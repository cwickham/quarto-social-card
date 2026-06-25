# quarto-social-card

A Quarto filter that renders an Open Graph social card (1200×630 PNG) from a
document's metadata — title, subtitle, image — styled with your project's
`_brand.yml` colours and fonts. The card is compiled with the Typst binary
bundled with Quarto, in the same render as your site. No second command, no
stray files.

![The extension's own social card: "quarto-social-card / Social cards from your Quarto metadata", with an example card alongside](https://cwickham.github.io/quarto-social-card/thumbnail.png)

## Usage

Add the extension to your project:

```bash
quarto add cwickham/quarto-social-card
```

Add the filter to the page you want a card for, and point the page's social
image at the card the filter generates. By default the card is written next to
the document as `<document>-social-card.png`:

```yaml
title: "Alicia"
subtitle: "Data Scientist"
image: profile.jpg
filters:
  - social-card
open-graph:
  image: index-social-card.png
  image-alt: "Alicia, Data Scientist" # the card's text, for screen readers
twitter-card:
  image: index-social-card.png
  image-alt: "Alicia, Data Scientist"
```

Render the site as usual:

```bash
quarto render
```

The filter reads the page `title` / `subtitle` / `image`, compiles the card,
publishes it alongside the page, and the `open-graph` / `twitter-card` entries
make Quarto emit it as the `og:image` / `twitter:image`. The card is rebuilt
only when its content or brand changes (it is cached under
`.quarto/social-card/`).

> The filter logs the exact `open-graph` / `twitter-card` block to copy on each
> render, so you do not have to guess the filename.

Colours and fonts come from your `_brand.yml` through Quarto's brand API.
`source: google` brand fonts are fetched on the first render (cached under
`.quarto/typst/fonts/`); system fonts are used directly. Local (`source: file`)
and Bunny fonts are not embedded in the card.

## Options

Options live under an `extensions.social-card` block in the page front matter
(or `_quarto.yml`). `image-shape` and `brand-mode` may also be set at the top
level.

```yaml
extensions:
  social-card:
    image-shape: round
    brand-mode: dark
```

| Option        | Default                    | Description                                                         |
| ------------- | -------------------------- | ------------------------------------------------------------------- |
| `enabled`     | `true`                     | Generate the card for this document.                                |
| `title`       | document `title`           | Card title.                                                         |
| `subtitle`    | `subtitle` → `description` | Card subtitle.                                                      |
| `image`       | document `image`           | Card image (avatar).                                                |
| `image-shape` | `rectangle`                | `rectangle`, `round` (circle crop), or `rounded` (rounded corners). |
| `brand-mode`  | `light`                    | `light` or `dark` brand variant.                                    |
| `filename`    | `<document>-social-card`   | Output filename stem.                                               |
| `output-dir`  | next to the document       | Output directory. A leading `/` is the project root.                |

### Change the image shape

By default the image is shown as a **rectangle** at its natural aspect ratio.
Set `image-shape` to `round` (circle crop) or `rounded` (rounded corners),
mirroring Quarto's `about` template:

```yaml
image: profile.jpg
image-shape: round # round | rounded | rectangle (default)
```

### Override the brand for one card

To give a card different colours or fonts, add a `brand` block to its front
matter. A document-level `brand` **replaces** the project `_brand.yml`, so
respecify everything you want — including typography, or the card falls back to
Typst's default font:

```yaml
title: "Alicia"
subtitle: "Data Scientist"
image: profile.jpg
filters:
  - social-card
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
```

> [!NOTE]
> Variable Google fonts need explicit weights. The card requests the static
> 400 and 700 faces; brands that only declare a variable font still render
> correctly because the filter fetches those weights for you.

### Use a brand's dark mode

A card is a static image, so it has no automatic dark mode. If your `_brand.yml`
defines light and dark variants, set `brand-mode: dark` to render the dark one:

```yaml
title: "Alicia"
brand-mode: dark
filters:
  - social-card
```

### Choose where the card is written

```yaml
extensions:
  social-card:
    filename: alicia-card # writes alicia-card.png
    output-dir: /social-cards # leading / = project root
```

## Limitations

- Cards are generated for HTML output only.
- The card is referenced through `open-graph` / `twitter-card` metadata, which
  you set once per page (Quarto resolves those before filters run, so the
  filter cannot set them for you).

## Development

### Repository layout

This repository is two Quarto sites plus the extension:

- `_extensions/social-card/` — the extension itself (what `quarto add` installs).
- Root site — the documentation/landing site (`index.qmd`, `_quarto.yml`,
  `_brand.yml`). It dogfoods the extension: `index.qmd` carries the filter to
  generate this project's own card (`thumbnail.png`).
- `_examples/` — a standalone demo site showing the extension in use, with its
  own `_quarto.yml` and `_brand.yml`. `_examples/example-card.png` is a sample
  card used as the avatar inside the project's own card.
- `_tests/` — golden-image tests (`render.sh` and `expected/`).

Generated cards (`thumbnail.png`, `*-social-card.png`) are not committed; the
test goldens under `_tests/expected/` are.

### Tests

`_tests/render.sh` renders each case under `_tests/cases/` through the filter
and collects the generated card as a golden PNG in `_tests/expected/`. Each case
is a directory holding a `card.qmd` plus an optional `_brand.yml` (or a
`.no-brand` marker; with neither, `_examples/_brand.yml` is used). Cases cover
the default, long title, long subtitle, both long, missing title / subtitle /
image, image shapes (round, rounded), no brand, and a brand with downloaded
(Google) fonts.

```bash
./_tests/render.sh
```

(The downloaded-fonts case needs network access on first run.)
