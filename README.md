# quarto-social-card

A Quarto Typst format that renders an Open Graph social card (1200×630 PNG) from
a document's metadata — title, subtitle, image — styled with your project's
`_brand.yml` colors and fonts.

Quarto can emit the `og:image` metadata (`open-graph: true`) but you still have
to supply the image. This makes that image from metadata you already have.

> **Status: working spike.** The format lives in `_extensions/social-card/`.
> The interface (config keys, field mapping) is still being designed — see
> [`PLAN.md`](PLAN.md).

## Usage

### 1. Create a card document

Make a `_thumbnail.qmd` (the leading `_` keeps it out of your rendered site) and
set the card content in its front matter:

```yaml
---
title: "Alicia"
subtitle: "Data Scientist"
image: profile.jpg
format:
  social-card-typst: default
---
```

Brand colors and fonts are pulled automatically from `_brand.yml` — you don't
set them here.

#### Overriding the brand for one card

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

### 2. Render it to a PNG

The format renders to PDF (and, with `keep-typ`, leaves the `.typ`); a second
command rasterizes that to PNG:

```bash
quarto render _thumbnail.qmd
quarto typst compile _thumbnail.typ thumbnail.png --font-path .quarto/typst/fonts --ppi 144
```

You now have `thumbnail.png`, a 1200×630 social card.

The `--font-path .quarto/typst/fonts` points at the cache where `quarto render`
downloads brand fonts (Google/Bunny), so the card uses them. It's harmless if
your brand uses only system fonts — Typst just falls back as usual.

### 3. Wire it up as your site's social image

In `_quarto.yml`, point the `website` key at the card and make sure Open Graph
is on:

```yaml
website:
  open-graph: true
  image: thumbnail.png   # site-wide default og:image / twitter-card
```

Individual pages can still override this with their own `image:` front matter.
Re-run the two commands in step 2 whenever the title, subtitle, image, or brand
changes.

### Using it on an existing page

Instead of a dedicated `_thumbnail.qmd`, you can add the format to any page
alongside its normal output:

```yaml
format:
  html: default
  social-card-typst: default
```

`quarto render page.qmd` then produces both the HTML page and the card
(`page.typ` → `page.pdf`); rasterize `page.typ` to PNG just as in step 2. The
card uses that page's `title` / `subtitle` / `image`, and the page **body is
ignored** — only the metadata reaches the card.

Two caveats: in a website project the card `page.pdf` is written into `_site/`
alongside the HTML (a stray file you may want to clean up), and you rasterize
each page individually.

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
