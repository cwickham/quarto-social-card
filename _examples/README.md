# Example site

A standalone Quarto website demonstrating the `social-card` extension in use.

It is a small "about me" page (`index.qmd`) with its own `_quarto.yml` and
`_brand.yml`. A `pre-render` step copies the extension from the parent
repository into `_extensions` for the render, and `post-render` removes it, so
the demo always uses the current code without a committed copy.

Render it like any Quarto site:

```bash
cd _examples
quarto render
```

The `social-card` filter on `index.qmd` generates `index-social-card.png`, wired
into `open-graph` / `twitter-card`. `example-card.png` is a pre-made card used as
the avatar inside this project's own social card (see the root `index.qmd`).
