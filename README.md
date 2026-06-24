# quarto-social-card

A Quarto Typst format that renders an Open Graph social card (1200×630 PNG) from
a document's metadata — title, subtitle, image — styled with your project's
`_brand.yml` colors and fonts.

![A social card reading "Alicia, Data Scientist" beside a circular photo, in the project's brand colors](thumbnail.png)

## Usage

Add the extension to your project:

```bash
quarto add cwickham/quarto-social-card
```

Create a `_thumbnail.qmd` with your card's content. The leading `_` keeps it out
of the rendered site; colors and fonts come from your `_brand.yml`:

```yaml
---
title: "Alicia"
subtitle: "Data Scientist"
image: profile.jpg
format:
  social-card-typst: default
---
```

Render it to a 1200×630 PNG:

```bash
quarto render _thumbnail.qmd
quarto typst compile _thumbnail.typ thumbnail.png --font-path .quarto/typst/fonts --ppi 144
```

(The `--font-path` lets the card use brand fonts that `quarto render` downloaded;
it's harmless if your brand uses only system fonts.)

Wire the card into `_quarto.yml` as your site's social image. Add `image-alt` so
the shared preview is accessible:

```yaml
website:
  open-graph: true
  image: thumbnail.png
  image-alt: "Alicia, Data Scientist" # the card's text, for screen readers
```

Re-run the two render commands whenever the content or brand changes.

For overriding the brand on a single card, or making cards from existing pages,
see [More ways to use it](#more-ways-to-use-it).

## More ways to use it

### Override the brand for one card

To give a card different colors or fonts, add a `brand` block to its front
matter. Note that a document-level `brand` **replaces** the project `_brand.yml`
rather than extending it, so respecify everything you want — including
typography, or the card falls back to Typst's default font:

```yaml
---
title: "Alicia"
subtitle: "Data Scientist"
image: profile.jpg
brand:
  color:
    background: "#1a1a2e"
    foreground: "#ffffff"
    primary: "#e94560"
  typography:
    base:
      family: "Avenir Next"
    headings:
      family: "Baskerville"
format:
  social-card-typst: default
---
```

### Add a card to an existing page

Instead of a dedicated `_thumbnail.qmd`, you can add the format to any page
alongside its normal output:

```yaml
format:
  html: default
  social-card-typst: default
```

Rendering produces both the HTML page and the card (`page.typ` → `page.pdf`);
rasterize the kept `page.typ` to a PNG, named to match what you reference below:

```bash
quarto render page.qmd
quarto typst compile page.typ page-card.png --font-path .quarto/typst/fonts --ppi 144
```

The card uses that page's `title` / `subtitle` / `image`, and the page **body is
ignored** — only the metadata reaches the card.

Then point the page's social image at the generated card. Quarto otherwise uses
the page's `image:` (the card's avatar) as the `og:image`, so set it explicitly
under `open-graph` (and `twitter-card`):

```yaml
image: profile.jpg          # shown on the social card, listings and about template
open-graph:
  image: page-card.png      # the generated card 
  image-alt: "Alicia, Data Scientist"  # the card's text, for screen readers
twitter-card:
  image: page-card.png
  image-alt: "Alicia, Data Scientist"  # the card's text, for screen readers
```

Be aware that the card `page.pdf` is published into `_site/`. 
Consider deleting it, or using a `post-render` script to remove it.

## Development

### Tests

`_tests/render.sh` renders each case under `_tests/cases/` through the format and
rasterizes it to a golden PNG in `_tests/expected/`. Each case is a directory
holding a `card.qmd` plus an optional `_brand.yml` (or a `.no-brand` marker; with
neither, the project's own `_brand.yml` is used). Cases cover the default, long
title, long subtitle, both long, missing title / subtitle / image, no brand, and
a brand with downloaded (Google) fonts.

```bash
./_tests/render.sh
```

(The downloaded-fonts case needs network access on first run.)
