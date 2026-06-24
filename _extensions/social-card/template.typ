// Full Typst template for the social card (1200x630 Open Graph card).
//
// We render a fixed card from metadata, not a document body, so this replaces
// Quarto's whole Typst template. The one piece we keep is the header-includes
// loop below: it carries Quarto's brand injection (`brand-color`, brand font
// `#set`/`#show` rules). Keeping it BEFORE our layout means `brand-color` is
// already in scope when we use it.

$for(header-includes)$
$header-includes$

$endfor$

// ---- metadata (document front matter + brand) ------------------------------
#let card-title = [$title$]
#let card-subtitle = [$subtitle$]
$if(image)$
// Pandoc markdown-escapes `_` in the path (e.g. `_examples/x.png` -> `\_examples/x.png`); undo that.
#let card-image = "$image$".replace("\\_", "_")
$else$
#let card-image = none
$endif$
$if(image-shape)$
#let image-shape = "$image-shape$"
$else$
#let image-shape = "rectangle"
$endif$
$if(brand.typography.base.family)$
#let base-font = $brand.typography.base.family$
$else$
#let base-font = none
$endif$
$if(brand.typography.headings.family)$
#let heading-font = $brand.typography.headings.family$
$else$
#let heading-font = none
$endif$

// ---- brand colors (brand-color injected above; safe fallbacks) -------------
#let fg = brand-color.at("foreground", default: rgb("#000000"))
#let bg = brand-color.at("background", default: rgb("#ffffff"))
#let accent = brand-color.at("primary", default: fg)

// ---- geometry --------------------------------------------------------------
#let ppi = 144
#let card-width = 1200 / ppi * 1in
#let card-height = 630 / ppi * 1in
#let pad-x = (left: 1.6cm, right: 1.4cm)
#let pad-y = 1.2cm
#let gutter = 1.4cm
#let gap = 0.9cm
#let avatar-size = 7.5cm
#let text-width = card-width - pad-x.left - pad-x.right - gutter - avatar-size

// Pass `font` through to text(), but omit the argument entirely when none
// (brandless or colors-only docs) — Typst's text(font: none) is an error, so we
// let it fall back to the default font instead.
#let _font(f) = if f == none { (:) } else { (font: f) }

// ---- fit helpers (decide sizes at full card width, not the grid cell) ------
#let fit-line-size(body, font: none, width: text-width, size: 72pt, min-size: 16pt, step: 1pt) = {
  let s = size
  let target = width - 0.25cm
  while s > min-size and measure(text(.._font(font), weight: "bold", size: s, body)).width > target {
    s -= step
  }
  s
}

#let fit-wrap-size(body, font: none, width: text-width, lines: 2, size: 28pt, min-size: 14pt, step: 1pt) = {
  let s = size
  while s > min-size {
    let h1 = measure(box(text(.._font(font), size: s)[Ag])).height
    let h2 = measure(box(text(.._font(font), size: s)[Ag #linebreak() Ag])).height
    let budget = h1 + (lines - 1) * (h2 - h1) + 0.5pt
    let h = measure(box(width: width, text(.._font(font), weight: "medium", size: s, body))).height
    if h <= budget { break }
    s -= step
  }
  s
}

// ---- page + layout ----------------------------------------------------------
#set page(width: card-width, height: card-height, margin: 0pt, fill: bg)
#set text(fill: fg)

// `shape` mirrors Quarto's `about` template: round (circle), rounded (rounded
// corners), rectangle (square corners). `round` crops the image to a square;
// the others show the whole image at its natural aspect ratio, fit to `size`.
#let avatar(path, size, shape) = {
  if shape == "rectangle" or shape == "rounded" {
    let radius = if shape == "rounded" { 0.4cm } else { 0pt }
    // fit within a size x size area at natural aspect: constrain the longer
    // side to `size` so tall (portrait) images can't overflow the card.
    // (called from the layout's #context, so measure() works here directly)
    let nat = measure(image(path))
    let img = if nat.width >= nat.height { image(path, width: size) } else { image(path, height: size) }
    box(radius: radius, clip: true, img)
  } else {
    box(width: size, height: size, radius: 50%, clip: true,
      image(path, width: size, height: size, fit: "cover"))
  }
}

// accent rail down the left edge
#place(left + top, rect(width: 0.4cm, height: 100%, fill: accent))

#context {
  let title-size = fit-line-size(card-title, font: heading-font, width: text-width)
  let subtitle-size = fit-wrap-size(card-subtitle, font: base-font, width: text-width)

  block(width: 100%, height: 100%, inset: (..pad-x, y: pad-y),
    grid(
      columns: (text-width, avatar-size),
      rows: 100%,
      align: horizon,
      gutter: gutter,
      // left: title + subtitle, vertically centred as a block (grid horizon)
      {
        text(.._font(heading-font), size: title-size, weight: "bold", fill: fg, card-title)
        v(gap)
        box(width: text-width, text(.._font(base-font), size: subtitle-size, weight: "medium", fill: accent, card-subtitle))
      },
      // right: image, centred in its column
      if card-image != none { align(center, avatar(card-image, avatar-size, image-shape)) },
    ),
  )
}
