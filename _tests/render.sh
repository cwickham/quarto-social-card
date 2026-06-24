#!/usr/bin/env bash
# Regenerate the social-card test fixtures by driving the extension.
#
# Each case is a directory under _tests/cases/ containing a `card.qmd` (the
# front matter under test) and one of:
#   _brand.yml   -> render with that brand
#   .no-brand    -> render with no brand at all
#   (neither)    -> render with the project's own _brand.yml
#
# For each case we render card.qmd through the social-card-typst format, then
# rasterize the kept .typ to _tests/expected/<case>.png — the same two-step
# flow documented in the README.
#
#   ./_tests/render.sh
#
# Note: the downloaded-fonts case needs network access (Quarto fetches the
# Google fonts on first render).
set -euo pipefail
cd "$(dirname "$0")/.."

EXPECTED="_tests/expected"
mkdir -p "$EXPECTED"

# Preserve the project's real _brand.yml and restore it (and clean scratch) on exit.
had_brand=0
[ -f _brand.yml ] && { cp _brand.yml _tests/.brand-backup.yml; had_brand=1; }
cleanup() {
  if [ "$had_brand" = 1 ]; then cp _tests/.brand-backup.yml _brand.yml; else rm -f _brand.yml; fi
  rm -f _tests/.brand-backup.yml _card.qmd _card.typ _card.pdf
  rm -rf _site .quarto
}
trap cleanup EXIT

for dir in _tests/cases/*/; do
  name="$(basename "$dir")"

  # set up the brand for this case
  if [ -f "$dir/_brand.yml" ]; then
    cp "$dir/_brand.yml" _brand.yml
  elif [ -f "$dir/.no-brand" ]; then
    rm -f _brand.yml
  elif [ "$had_brand" = 1 ]; then
    cp _tests/.brand-backup.yml _brand.yml
  fi

  cp "$dir/card.qmd" _card.qmd
  quarto render _card.qmd >/dev/null 2>&1
  quarto typst compile _card.typ "$EXPECTED/$name.png" \
    --font-path .quarto/typst/fonts --ppi 144 >/dev/null 2>&1
  echo "rendered $EXPECTED/$name.png"
done
