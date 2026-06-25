// Social Card - Typst Template
// Self-contained 1200x630 Open Graph card rendered from filter-supplied values.
//
// @license MIT
// @copyright 2026 Charlotte Wickham
// @author Charlotte Wickham
//
// The card is rendered from metadata, not a document body. Every brand value
// (colours and fonts) is supplied by the social-card Lua filter through the
// Pandoc template variables below, so this `.typ` compiles standalone with the
// bundled Typst binary -- no Quarto Typst-format scaffolding required.

// ---- values injected by the filter -----------------------------------------
#let card-title = [$title$]
#let card-subtitle = [$subtitle$]
$if(image)$
#let card-image = "$image$"
$else$
#let card-image = none
$endif$
#let image-shape = "$image-shape$"
#let base-font = $base-font$       // a Typst string literal, or `none`
#let heading-font = $heading-font$ // a Typst string literal, or `none`

// ---- brand colours (hex strings injected by the filter) --------------------
#let fg = rgb("$foreground$")
#let bg = rgb("$background$")
#let accent = rgb("$primary$")

// ---- geometry --------------------------------------------------------------
#let ppi = 144
#let card-width = 1200 / ppi * 1in
#let card-height = 630 / ppi * 1in
#let pad-x = (left: 1.6cm, right: 1.4cm)
#let pad-y = 1.2cm
#let gutter = 1.4cm
#let avatar-size = 7.5cm
#let text-width = card-width - pad-x.left - pad-x.right - gutter - avatar-size

// Pass `font` through to text(), but omit the argument entirely when none
// (brandless or colors-only docs) -- Typst's text(font: none) is an error, so we
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
        // kill auto paragraph spacing (it defaults to 1.2em of the 72pt title!);
        // the natural line metrics then give a gap that scales with font size,
        // plus a small extra v()
        set par(spacing: 0pt)
        text(.._font(heading-font), size: title-size, weight: "bold", fill: fg, card-title)
        v(subtitle-size * 0.8)
        box(width: text-width, text(.._font(base-font), size: subtitle-size, weight: "medium", fill: accent, card-subtitle))
      },
      // right: image, centred in its column
      if card-image != none { align(center, avatar(card-image, avatar-size, image-shape)) },
    ),
  )
}
