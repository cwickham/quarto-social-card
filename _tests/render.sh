#!/usr/bin/env bash
#
# Social Card - Test fixture renderer
# Regenerate the social-card test fixtures by driving the extension filter.
#
# @license MIT
# @copyright 2026 Charlotte Wickham
# @author Charlotte Wickham
#
# Each case is a directory under _tests/cases/ containing a `card.qmd` (the
# front matter under test) and one of:
#   _brand.yml   -> render with that brand
#   .no-brand    -> render with no brand at all
#   (neither)    -> render with _examples/_brand.yml (a stable test brand,
#                   independent of this doc-site's own _brand.yml)
#
# For each case we render card.qmd through the social-card filter; the filter
# compiles the card to a PNG next to the document, which we collect as the
# golden image in _tests/expected/<case>.png.
#
#   ./_tests/render.sh
#
# Note: the downloaded-fonts case needs network access (the filter fetches the
# Google fonts on first render).
set -euo pipefail
cd "$(dirname "$0")/.."

EXPECTED="_tests/expected"
mkdir -p "$EXPECTED"

# Preserve the project's real _brand.yml and restore it (and clean scratch) on exit.
had_brand=0
[ -f _brand.yml ] && { cp _brand.yml _tests/.brand-backup.yml; had_brand=1; }
# Cases reference images by bare name; stage the shared fixtures at the render
# root for the duration (profile.jpg from the example, portrait.jpg for the
# height-bound case).
cp _examples/profile.jpg profile.jpg
cp _tests/portrait.jpg portrait.jpg
cleanup() {
  if [ "$had_brand" = 1 ]; then cp _tests/.brand-backup.yml _brand.yml; else rm -f _brand.yml; fi
  rm -f _tests/.brand-backup.yml _card.qmd _card.html _card-social-card.png profile.jpg portrait.jpg
  rm -rf _card_files _site .quarto
}
trap cleanup EXIT

for dir in _tests/cases/*/; do
  name="$(basename "$dir")"

  # set up the brand for this case
  if [ -f "$dir/_brand.yml" ]; then
    cp "$dir/_brand.yml" _brand.yml
  elif [ -f "$dir/.no-brand" ]; then
    rm -f _brand.yml
  else
    cp _examples/_brand.yml _brand.yml
  fi

  cp "$dir/card.qmd" _card.qmd
  rm -f _card-social-card.png
  quarto render _card.qmd >/dev/null 2>&1
  cp _card-social-card.png "$EXPECTED/$name.png"
  echo "rendered $EXPECTED/$name.png"
done
