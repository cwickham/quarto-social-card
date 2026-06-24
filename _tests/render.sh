#!/usr/bin/env bash
# Regenerate the social-card test fixtures.
#
# Each case overrides the `title` / `subtitle` values in social-card.typ and
# renders the result to _tests/expected/<case>.png. The case definitions below
# ARE the test parameters — edit here to add or change a case, then re-run.
#
#   ./_tests/render.sh            # regenerate all goldens
#
# The temporary .typ is written to the repo root so the template's relative
# `profile.jpg` path resolves.
set -euo pipefail
cd "$(dirname "$0")/.."

render() {
  local name="$1" title="$2" subtitle="$3"
  local tmp=".case-${name}.typ"
  # escape `&` and `|` so they aren't special in the sed replacement
  title="${title//&/\\&}"; subtitle="${subtitle//&/\\&}"
  sed -e "s|#let title = \"Alicia\"|#let title = \"${title}\"|" \
      -e "s|#let subtitle = \"Data Scientist\"|#let subtitle = \"${subtitle}\"|" \
      social-card.typ > "$tmp"
  quarto typst compile "$tmp" "_tests/expected/${name}.png" --ppi 144
  rm -f "$tmp"
  echo "rendered _tests/expected/${name}.png"
}

render default       "Alicia"                          "Data Scientist"
render long-title    "Alicia Featherstone-Worthington" "Data Scientist"
render long-subtitle "Alicia"                          "Principal Data Scientist & Machine Learning Engineering Lead"
render both-long     "Alicia Featherstone-Worthington" "Principal Data Scientist & Machine Learning Engineering Lead"
