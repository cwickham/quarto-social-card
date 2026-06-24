// social-card.typ — generates an Open Graph social card (1200x630).
// Prototype: values below are hardcoded. Later these will be read from
// metadata — front matter of `index.qmd` (title/subtitle/image) and `_brand.yml`.

// ---- DATA (to be sourced from metadata later) ------------------------------
// from index.qmd front matter
#let title = "Alicia"
#let subtitle = "Data Scientist"
#let image-path = "profile.jpg"

// from _brand.yml
#let brand-foreground = rgb("#333333")
#let brand-background = rgb("#ffffff")
#let brand-primary = rgb("#2A9D8F")
#let brand-font-base = "Avenir Next"     // typography.base.family
#let brand-font-heading = "Baskerville"  // typography.headings.family

// ---- CARD GEOMETRY ---------------------------------------------------------
// Open Graph recommended size: 1200x630 px. Exported at --ppi 144.
#let ppi = 144
#let card-width = 1200 / ppi * 1in
#let card-height = 630 / ppi * 1in

// layout measurements (also used to size text to the available space)
#let pad-x = (left: 1.6cm, right: 1.4cm)
#let pad-y = 1.2cm
#let gutter = 1.4cm
#let gap = 0.9cm // vertical gap between title and subtitle, centred on the card
#let avatar-size = 7.5cm
#let text-width = card-width - pad-x.left - pad-x.right - gutter - avatar-size

// ---- FIT HELPERS -----------------------------------------------------------
// These return a *font size*, not content, and must be called inside a `context`
// whose region is wider than the text (e.g. the top level of the card, not a
// narrow grid cell — measure() is region-aware and would otherwise pre-wrap).

// Largest size at which `body` fits on a single line no wider than `width`.
#let fit-line-size(body, width: text-width, size: 72pt, min-size: 16pt, step: 1pt) = {
  let s = size
  // leave a little slack so a near-exact fit can't tip onto a second line
  let target = width - 0.25cm
  // measure at the SAME weight the title renders at — bold is wider than regular
  while s > min-size and measure(text(font: brand-font-heading, weight: "bold", size: s, body)).width > target {
    s -= step
  }
  s
}

// Largest size at which `body` wraps to at most `lines` lines within `width`.
#let fit-wrap-size(body, width: text-width, lines: 2, size: 28pt, min-size: 14pt, step: 1pt) = {
  let s = size
  while s > min-size {
    // derive the line advance by measuring a real 1- and 2-line block
    let h1 = measure(box(text(font: brand-font-base, size: s)[Ag])).height
    let h2 = measure(box(text(font: brand-font-base, size: s)[Ag #linebreak() Ag])).height
    let budget = h1 + (lines - 1) * (h2 - h1) + 0.5pt
    let h = measure(box(width: width, text(font: brand-font-base, weight: "medium", size: s, body))).height
    if h <= budget { break }
    s -= step
  }
  s
}

// ---- DESIGN ----------------------------------------------------------------
#set document(title: title)
#set text(font: brand-font-base, fill: brand-foreground)
#set page(
  width: card-width,
  height: card-height,
  margin: 0pt,
  fill: brand-background,
)

// circular crop of the profile image (matches `about: jolla`)
#let avatar(path, size) = box(
  width: size,
  height: size,
  radius: 50%,
  clip: true,
  image(path, width: size, height: size, fit: "cover"),
)

// accent rail down the left edge
#place(left + top, rect(width: 0.4cm, height: 100%, fill: brand-primary))

// Decide text sizes here, at the full card width, then render the grid at those
// sizes — keeping the size decision out of the narrow (region-aware) grid cell.
#context {
  let title-size = fit-line-size(title)
  let subtitle-size = fit-wrap-size(subtitle)

  block(
    width: 100%,
    height: 100%,
    inset: (..pad-x, y: pad-y),
    grid(
      columns: (text-width, avatar-size),
      rows: 100%,
      align: horizon, // vertically centre the avatar
      gutter: gutter,
      // left: title bottom-aligned above centre, subtitle top-aligned below,
      // the gap between them straddling the (avatar-aligned) vertical centre
      block(width: 100%, height: 100%, grid(
        rows: (1fr, 1fr),
        row-gutter: gap,
        align(bottom + left,
          text(font: brand-font-heading, size: title-size, weight: "bold", fill: brand-foreground, title)),
        align(top + left,
          box(width: text-width, text(font: brand-font-base, size: subtitle-size, weight: "medium", fill: brand-primary, subtitle))),
      )),
      // right: circular avatar
      avatar(image-path, avatar-size),
    ),
  )
}
