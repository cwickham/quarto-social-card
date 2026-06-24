# Plan: turn the prototype into a Quarto extension

## Goal

Drop the extension into a Quarto website and have social cards generated
automatically from metadata already in the project — no per-page image wrangling.
For each page (or a configured subset): render a 1200×630 PNG from the page
title/subtitle/image + brand, write it into the site, and make Quarto's
`open-graph` / `twitter-card` use it.

## Where we are

`social-card.typ` is a working Typst template: brand colors + fonts, circular
avatar, shrink-to-fit title (one line) and subtitle (up to two lines),
centre-anchored layout. Values are hardcoded `#let`s grouped by source
(`index.qmd` front matter / `_quarto.yml` / `_brand.yml`). `_tests/` captures
representative inputs and their golden outputs.

## Mechanism — how the extension runs

Quarto extensions that *do* something at render time are either **Lua filters**
or **pre/post-render scripts**. Leaning toward a **Lua filter**:

- Runs per document with the page metadata already resolved → title, subtitle,
  description, `image` are in hand.
- Can **set `meta.image`** when it's unset, so Quarto's built-in Open Graph
  picks the generated card up automatically (no manual `<meta>` injection).
- Generation = write a `.typ` from a template + values, shell out to
  `quarto typst compile`, write the PNG into a known output dir.

Open concerns to validate (spikes):
1. **Shelling out to Typst from inside a render** — nested `quarto` call cost;
   may prefer bundled `typst` directly. Needs **caching**: hash the inputs and
   skip recompile when unchanged (per-page cards otherwise rebuild every render).
2. **Reading `_brand.yml`** — confirm whether resolved brand is available in Lua
   `meta`, or whether we read/parse the file from the project root ourselves
   (Lua has no YAML; may need a tiny parser or a pre-render step that emits JSON).
3. **Fonts** — Typst only sees locally-installed fonts. A brand using Google
   fonts won't render in Typst without the font files. Need a resolution
   strategy: install/embed, map to a fallback, or document the requirement.

If the per-page filter proves awkward, fall back to a **post-render script**
that iterates pages via `quarto inspect` and writes cards, injecting `og:image`
into the output HTML.

## Metadata sources (mapping to map out with you)

| Card field | Likely source |
|-----------|----------------|
| title     | page `title` → fallback `website.title` |
| subtitle  | page `subtitle` / `description` |
| image     | page `image` (the avatar) |
| colors    | `_brand.yml` color (foreground/background/primary) |
| fonts     | `_brand.yml` typography base/headings |

## Open questions — interface (let's discuss)

These shape the public API, so they're yours to drive:

- **Config key & scope** — a `social-card:` block in `_quarto.yml`? Per-page
  front-matter overrides? On-by-default or opt-in per page?
- **Field mapping** — which metadata fields feed title/subtitle/image, and what
  the fallbacks are (e.g. subtitle vs description).
- **Template customization** — ship one template, or let users point at their
  own `.typ`? Expose knobs (avatar on/off, layout variants, size/ppi) via config?
- **Output** — where cards are written and how they're named (per-page slug?).
- **Scope of v1** — site-level card only, or per-page from the start?

## Milestones (draft)

1. Extension skeleton — `_extensions/cwickham/social-card/_extension.yml` + Lua filter.
2. MVP filter: metadata-driven title/subtitle/image (hardcode brand).
3. Brand integration (colors + fonts) + font strategy.
4. Template as a bundled resource + customization hook.
5. Caching + performance.
6. Tests: drive the `_tests/` cases through the extension, not just raw Typst.
7. Docs + example site.
