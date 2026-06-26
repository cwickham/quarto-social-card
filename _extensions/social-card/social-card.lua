--- Social Card - Filter
--- @module "social-card"
--- @license MIT
--- @copyright 2026 Charlotte Wickham
--- @author Charlotte Wickham
--- @brief Generate an Open Graph social card (1200x630 PNG) from page metadata.
--- @description Reads the page title/subtitle/image plus the project brand,
--- compiles a Typst card to PNG with the Typst binary bundled with Quarto, and
--- writes it to a predictable path to reference from open-graph/twitter-card.

local EXTENSION_NAME = 'social-card'

local stringify = pandoc.utils.stringify

--- Log an error with the extension prefix.
--- @param message string
local function log_error(message)
  quarto.log.error('[' .. EXTENSION_NAME .. '] ' .. message)
end

--- Log an informational message with the extension prefix.
--- @param message string
local function log_output(message)
  quarto.log.output('[' .. EXTENSION_NAME .. '] ' .. message)
end

--- Whether a value is nil or the empty string.
--- @param s any
--- @return boolean
local function is_empty(s)
  return s == nil or s == ''
end

--- Escape a string for use inside a Typst string literal (`"..."`).
--- @param text string
--- @return string
local function escape_typst_string(text)
  local result = text
      :gsub('\\', '\\\\')
      :gsub('"', '\\"')
      :gsub('\n', '\\n')
      :gsub('\r', '\\r')
      :gsub('\t', '\\t')
  return result
end

--- Default option values.
local DEFAULTS = {
  enabled = true,
  ['image-shape'] = 'rectangle',
  ppi = 144,
}

--- Cache and font directories, relative to the project scratch directory.
local CACHE_SUBDIR = pandoc.path.join({ '.quarto', 'social-card' })
local FONT_SUBDIR = pandoc.path.join({ '.quarto', 'typst', 'fonts' })

--- Resolve a project-scratch subdirectory to an absolute path anchored at the
--- project root, so the cache is shared no matter which document renders.
--- @param subdir string
--- @return string
local function project_path(subdir)
  local root = quarto.project.directory
  return root and pandoc.path.join({ root, subdir }) or subdir
end

-- ============================================================================
-- HELPERS
-- ============================================================================

--- Stringify a metadata value, returning nil when empty.
--- @param value any
--- @return string|nil
local function meta_string(value)
  if value == nil then return nil end
  local s = stringify(value)
  if is_empty(s) then return nil end
  return s
end

--- Read a metadata value from the `extensions.social-card` table, falling back
--- to a top-level key, then to the default.
--- @param meta table Document metadata
--- @param card table|nil The `extensions.social-card` metadata table
--- @param key string Option key
--- @param fallback_key string|nil Top-level metadata key to fall back to
--- @return string|nil
local function option(meta, card, key, fallback_key)
  if card and card[key] ~= nil then
    return meta_string(card[key])
  end
  if fallback_key and meta[fallback_key] ~= nil then
    return meta_string(meta[fallback_key])
  end
  local default = DEFAULTS[key]
  if default == nil then return nil end
  return tostring(default)
end

--- Read the file at `path` and return its full contents (binary-safe).
--- @param path string
--- @return string|nil
local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local content = f:read('*a')
  f:close()
  return content
end

--- Whether a file exists, without reading its contents.
--- @param path string
--- @return boolean
local function file_exists(path)
  local f = io.open(path, 'rb')
  if f then
    f:close()
    return true
  end
  return false
end

--- Write bytes to a file (binary-safe).
--- @param path string
--- @param bytes string
--- @return boolean Whether the write succeeded
local function write_file(path, bytes)
  local f = io.open(path, 'wb')
  if not f then return false end
  f:write(bytes)
  f:close()
  return true
end

--- Hash a string to a short hex stem for cache keys.
--- @param s string
--- @return string
local function short_hash(s)
  return pandoc.utils.sha1(s):sub(1, 8)
end

--- The brand mode to render, honouring `brand-mode` and falling back to light.
--- @param card table|nil
--- @return string 'light' or 'dark'
local function resolve_mode(meta, card)
  local mode = option(meta, card, 'brand-mode', 'brand-mode')
  if mode == 'dark' and quarto.brand.has_mode('dark') then
    return 'dark'
  end
  return 'light'
end

--- Resolve a brand colour to a hex string, with a fallback.
--- @param mode string
--- @param name string
--- @param fallback string
--- @return string
local function brand_color(mode, name, fallback)
  local ok, value = pcall(quarto.brand.get_color, mode, name)
  if ok and value and value ~= '' then
    return value
  end
  return fallback
end

--- Resolve a brand font family to a Typst string literal, or `none`.
--- @param mode string
--- @param name string 'base' or 'headings'
--- @return string Typst literal (e.g. '"Fraunces"' or 'none')
local function brand_font(mode, name)
  local ok, typography = pcall(quarto.brand.get_typography, mode, name)
  if ok and type(typography) == 'table' and typography.family then
    return '"' .. escape_typst_string(typography.family) .. '"'
  end
  return 'none'
end

--- Build the Google Fonts weight query for a font, always including the 400 and
--- 700 faces the card relies on. Accepts a scalar, a list, or an `a..b` range.
--- @param weight any
--- @return string Comma-separated weights (e.g. "400,700")
local function weight_query(weight)
  local set = { ['400'] = true, ['700'] = true }
  local function add(w)
    w = tostring(w):match('^%s*(.-)%s*$')
    local a, b = w:match('^(%d+)%.%.(%d+)$')
    if a then
      set[a], set[b] = true, true
    elseif w:match('^%d+$') then
      set[w] = true
    end
  end
  if type(weight) == 'table' then
    for _, w in ipairs(weight) do add(w) end
  elseif weight ~= nil then
    add(weight)
  end
  local list = {}
  for w in pairs(set) do list[#list + 1] = w end
  table.sort(list, function(x, y) return tonumber(x) < tonumber(y) end)
  return table.concat(list, ',')
end

--- Download the TrueType faces of a Google font family at the given weights into
--- the cache. A per-(family, weights) sentinel skips the network on later
--- renders (including the negative case of a system font with no Google faces).
--- @param family string
--- @param weights string Comma-separated weights
--- @param cache_dir string Absolute font cache directory
--- @return nil
local function download_google(family, weights, cache_dir)
  local checked_dir = pandoc.path.join({ cache_dir, '.checked' })
  pandoc.system.make_directory(checked_dir, true)
  local query = family:gsub(' ', '+')
  local sentinel = pandoc.path.join({ checked_dir, short_hash(query .. ':' .. weights) })
  if file_exists(sentinel) then return end
  local css_url = 'https://fonts.googleapis.com/css?family=' .. query .. ':' .. weights
  local ok, _, css = pcall(pandoc.mediabag.fetch, css_url, '.')
  if ok and css then
    for line in css:gmatch('[^\n]+') do
      local src = line:match('^%s*src:%s*(.-);%s*$')
      if src then
        -- Take the first TrueType/OpenType face of the line, as Quarto does
        -- (pandoc.ts); ignore the woff/woff2 alternatives Typst cannot use.
        for url, fmt in src:gmatch("url%(([^)]*)%)%s*format%('([^']*)'%)") do
          if fmt == 'truetype' or fmt == 'opentype' then
            local rel = url:gsub('^https?://', '')
            local dest = pandoc.path.join({ cache_dir, rel })
            if not file_exists(dest) then
              local fok, _, bytes = pcall(pandoc.mediabag.fetch, url, '.')
              if fok and bytes then
                pandoc.system.make_directory(pandoc.path.directory(dest), true)
                write_file(dest, bytes)
              end
            end
            break
          end
        end
      end
    end
  end
  write_file(sentinel, '')
end

--- Lowercased set of font families Typst can already resolve (system fonts),
--- cached for the process. Lets us skip a Google lookup for a family that is
--- already installed.
local system_families = nil

--- @param bin string Typst binary path
--- @return table Set of lowercased family names
local function available_families(bin)
  if system_families then return system_families end
  system_families = {}
  local ok, out = pcall(pandoc.pipe, bin, { 'fonts' }, '')
  if ok and type(out) == 'string' then
    for line in out:gmatch('[^\n]+') do
      local family = line:match('^%s*(.-)%s*$')
      if family ~= '' then system_families[family:lower()] = true end
    end
  end
  return system_families
end

--- The brand typography elements the card uses.
local FONT_ELEMENTS = { 'base', 'headings' }

--- Resolve the font directories Typst needs for the card's base and heading
--- families, using only the `quarto.brand` API. Each family is fetched from
--- Google at its element weight (always unioned with 400 and 700 so bold titles
--- never render thin). Families that are not Google fonts (system fonts) yield
--- no faces and fall back to Typst's own resolution; the per-family sentinel
--- caches that negative lookup. Local (`source: file`) and Bunny fonts are not
--- exposed by the brand API, so they are not embedded in the card.
--- @param mode string Brand mode ('light' or 'dark')
--- @param cache_dir string Absolute font cache directory
--- @param bin string Typst binary path
--- @return table List of `--font-path` directories
local function resolve_font_paths(mode, cache_dir, bin)
  local system = available_families(bin)
  local used = false
  for _, name in ipairs(FONT_ELEMENTS) do
    local ok, typography = pcall(quarto.brand.get_typography, mode, name)
    if ok and type(typography) == 'table' and typography.family then
      -- Only reach for Google when the family is not already installed.
      if not system[typography.family:lower()] then
        download_google(typography.family, weight_query(typography.weight), cache_dir)
        used = true
      end
    end
  end
  if used then return { cache_dir } end
  return {}
end

--- Resolve the card image to a Typst root-relative path (leading `/`), where the
--- Typst root is the project directory. Typst resolves a leading-`/` path
--- against `--root`, and a bare path against the (stdin) working directory.
--- @param image string|nil Image path as written in metadata
--- @return string|nil Root-relative path, or nil
--- @return string|nil Filesystem-absolute path (for cache hashing), or nil
local function resolve_image(image)
  if not image then return nil, nil end
  image = image:gsub('\\_', '_')
  local input = quarto.doc.input_file
  local doc_dir = input and pandoc.path.directory(input) or '.'
  local abs = pandoc.path.is_absolute(image) and image
      or pandoc.path.normalize(pandoc.path.join({ doc_dir, image }))
  local root = quarto.project.directory
  if root then
    local rel = pandoc.path.make_relative(abs, root)
    if rel and rel ~= '' and not rel:match('^%.%.') then
      return '/' .. rel, abs
    end
  end
  return abs, abs
end

--- Render the Typst source from the template and a context table.
--- @param context table Variable name -> string value
--- @return string|nil
local function render_source(context)
  local template_path = quarto.utils.resolve_path('template.typ')
  local template_text = read_file(template_path)
  if not template_text then
    log_error('Could not read template: ' .. tostring(template_path))
    return nil
  end
  local meta_context = {}
  for k, v in pairs(context) do
    meta_context[k] = pandoc.MetaString(v)
  end
  local compiled = pandoc.template.compile(template_text)
  -- apply() returns a pandoc Doc; :render() flattens it to a string. The Lua
  -- type stubs do not declare :render(), but it is part of the runtime API.
  ---@diagnostic disable-next-line: undefined-field
  return pandoc.template.apply(compiled, meta_context):render()
end

--- The default filename stem for a document's card: `<input-stem>-social-card`.
--- @return string
local function default_stem()
  local input = quarto.doc.input_file
  if not input then return 'social-card' end
  local stem = pandoc.path.split_extension(pandoc.path.filename(input))
  return stem .. '-social-card'
end

-- ============================================================================
-- FILTER
-- ============================================================================

--- Generate the social card PNG at a predictable path.
--- @param meta table Document metadata
--- @return nil
local function Meta(meta)
  if not quarto.doc.is_format('html') then
    return nil
  end

  local card = meta.extensions and meta.extensions[EXTENSION_NAME]
  if type(card) ~= 'table' then card = nil end

  if option(meta, card, 'enabled') == 'false' then
    return nil
  end

  local title = option(meta, card, 'title', 'title') or ''
  local subtitle = option(meta, card, 'subtitle', 'subtitle')
      or option(meta, card, 'subtitle', 'description')
      or ''

  local mode = resolve_mode(meta, card)
  local context = {
    title = title,
    subtitle = subtitle,
    ['image-shape'] = option(meta, card, 'image-shape', 'image-shape'),
    foreground = brand_color(mode, 'foreground', '#000000'),
    background = brand_color(mode, 'background', '#ffffff'),
    primary = brand_color(mode, 'primary', '#000000'),
    ['base-font'] = brand_font(mode, 'base'),
    ['heading-font'] = brand_font(mode, 'headings'),
  }

  local image, image_abs = resolve_image(option(meta, card, 'image', 'image'))
  if image then
    context.image = image
  end

  local source = render_source(context)
  if not source then
    return nil
  end

  -- Quarto resolves QUARTO_TYPST before the bundled binary, so this honours it.
  local bin = quarto.paths.typst()
  if not bin or bin == '' then
    log_error('Typst binary not found. Ensure Quarto >= 1.6 is installed.')
    return nil
  end

  -- Fonts: resolve the brand's font directories (downloading Google faces at the
  -- declared weights and staging local file fonts), best effort. Pointing Typst
  -- at these dirs is harmless when a family is a system font; Typst resolves
  -- system fonts on its own.
  local font_paths = resolve_font_paths(mode, project_path(FONT_SUBDIR), bin)

  -- Cache key over the rendered source, the image bytes, and the font paths.
  local hash_material = source
  if image_abs then
    hash_material = hash_material .. '|image:' .. (read_file(image_abs) or image_abs)
  end
  table.sort(font_paths)
  hash_material = hash_material .. '|fonts:' .. table.concat(font_paths, ';')
  local cache_stem = short_hash(hash_material)

  local cache_dir = project_path(CACHE_SUBDIR)
  pandoc.system.make_directory(cache_dir, true)
  local cached_png = pandoc.path.join({ cache_dir, cache_stem .. '.png' })

  if not file_exists(cached_png) then
    local root = quarto.project.directory or '.'
    local args = { 'compile', '--format', 'png', '--ppi', tostring(DEFAULTS.ppi), '--root', root }
    for _, dir in ipairs(font_paths) do
      args[#args + 1] = '--font-path'
      args[#args + 1] = dir
    end
    args[#args + 1] = '-'
    args[#args + 1] = cached_png
    local ok, err = pcall(pandoc.pipe, bin, args, source)
    if not ok then
      log_error('Typst compile failed: ' .. tostring(err))
      return nil
    end
  end

  -- Publish the card to a predictable path the user references from
  -- `open-graph.image` / `twitter-card.image`. `output-dir` follows Quarto's
  -- convention: a leading `/` is the project root, otherwise it is relative to
  -- the document.
  local input = quarto.doc.input_file
  local doc_dir = input and pandoc.path.directory(input) or '.'
  local stem = option(meta, card, 'filename') or default_stem()
  local out_name = stem .. '.png'
  local out_dir = option(meta, card, 'output-dir')

  local out_path, ref
  if out_dir then
    ref = out_dir:gsub('/$', '') .. '/' .. out_name
    if out_dir:sub(1, 1) == '/' then
      out_path = pandoc.path.join({ project_path(out_dir:sub(2)), out_name })
    else
      out_path = pandoc.path.join({ doc_dir, out_dir, out_name })
    end
    pandoc.system.make_directory(pandoc.path.directory(out_path), true)
  else
    out_path = pandoc.path.join({ doc_dir, out_name })
    ref = out_name
  end

  if not pandoc.path.is_absolute(out_path) and quarto.project.directory then
    out_path = pandoc.path.join({ quarto.project.directory, out_path })
  end
  out_path = pandoc.path.normalize(out_path)

  local png_bytes = read_file(cached_png)
  if not png_bytes then
    log_error('Card image was not produced: ' .. cached_png)
    return nil
  end
  if not write_file(out_path, png_bytes) then
    log_error('Could not write card image: ' .. out_path)
    return nil
  end

  -- Mirror the card into the project output directory so it is published
  -- without a manual `resources:` declaration.
  local out_root = quarto.project.output_directory
  local proj_root = quarto.project.directory
  if out_root and proj_root then
    local rel = pandoc.path.make_relative(pandoc.path.normalize(out_path), proj_root)
    if rel and rel ~= '' and not rel:match('^%.%.') then
      local published = pandoc.path.join({ out_root, rel })
      pandoc.system.make_directory(pandoc.path.directory(published), true)
      write_file(published, png_bytes)
    end
  end

  log_output(
    'Card written to ' .. out_path .. '. Reference it with:\n' ..
    'open-graph:\n  image: ' .. ref .. '\ntwitter-card:\n  image: ' .. ref
  )

  return nil
end

return {
  { Meta = Meta },
}
