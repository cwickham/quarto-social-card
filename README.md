# quarto-social-card

Auto-generate Open Graph social cards (1200×630 PNGs) for a Quarto website from
its own metadata — page front matter, project `_quarto.yml`, and `_brand.yml`
colors and fonts — using a [Typst](https://typst.app) template.

Quarto can emit the `og:image` metadata (`open-graph: true`) but you still have
to supply the image. This fills that gap: the card is rendered from the title,
subtitle, image, and brand you already have.

> **Status: prototype.** `social-card.typ` is a working Typst template with
> hardcoded values. The plan to turn it into a proper Quarto extension is in
> [`PLAN.md`](PLAN.md). The interface is still under discussion.

## Try the prototype

```bash
quarto typst compile social-card.typ images/social-card.png --ppi 144
```

The sample metadata it stands in for lives in `_quarto.yml` (the `website` key),
`index.qmd`-style front matter (title / subtitle / image), and `_brand.yml`
(colors + fonts).

## Tests

`_tests/render.sh` regenerates golden cards for a set of cases (default, long
title, long subtitle, both long) into `_tests/expected/`. The case definitions
in that script are the test parameters.

```bash
./_tests/render.sh
```
