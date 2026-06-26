// Social Card extension workflow.
// Mirrors `_extensions/social-card/social-card.lua` (`Meta`, lines 356-495).
// Compile: quarto typst compile _diagrams/workflow.typ _diagrams/workflow.svg
#import "@preview/cetz:0.5.2"

#set page(width: auto, height: auto, margin: 1cm)
#set text(size: 9pt)

#cetz.canvas({
  import cetz.draw: *

  // Okabe-Ito colourblind-safe palette (reddish purple omitted: no purple).
  let oi-skyblue = rgb("#56B4E9")
  let oi-blue = rgb("#0072B2")
  let oi-vermillion = rgb("#D55E00")
  let oi-orange = rgb("#E69F00")
  let oi-green = rgb("#009E73")

  let pstroke = oi-skyblue          // process
  let pfill = oi-skyblue.lighten(82%)
  let astroke = oi-blue             // accent (compile / terminator)
  let afill = oi-blue.lighten(85%)
  let sstroke = oi-vermillion       // stop
  let sfill = oi-vermillion.lighten(85%)
  let dstroke = oi-orange           // decision
  let dfill = oi-orange.lighten(82%)
  let cstroke = oi-green.lighten(35%) // cluster background
  let cfill = oi-green.lighten(92%)

  // A process / terminator box, auto-anchored by `name`.
  let node(pos, name, body, fill: pfill, stroke: pstroke) = content(
    pos,
    box(width: 3.7cm, inset: 6pt, align(center + horizon, body)),
    name: name, frame: "rect", fill: fill, stroke: stroke, padding: 0,
  )

  // A diamond decision. Tip coordinates are derived from (x, y, w, h).
  let dw = 1.75
  let dh = 1.1
  let decision(x, y, body) = {
    line(
      (x, y + dh), (x + dw, y), (x, y - dh), (x - dw, y),
      close: true, fill: dfill, stroke: dstroke,
    )
    content((x, y), box(width: 3cm, align(center + horizon, body)))
  }

  // An arrowed connector.
  let arrow(a, b) = line(a, b, mark: (end: ">", fill: black, scale: .9))

  // Edge label.
  let elabel(pos, body) = content(pos, text(8pt, fill: rgb("#555"))[#body])

  // Cluster caption, anchored to its top-left so arrows never clip it.
  let clabel(pos, body, anchor: "south-west") = content(pos, anchor: anchor, text(8pt, fill: rgb("#555"))[#body])

  // Spine y-positions. Wider gaps around the diamonds so every arrow is clear.
  let y-html = 0
  let y-opts = -2.2
  let y-en = -4.6     // decision
  let y-text = -7.0
  let y-mode = -9.2
  let y-brand = -11.4
  let y-image = -13.6
  let y-source = -15.8
  let y-bin = -18.0
  let y-sys = -20.4   // decision
  let y-key = -22.8
  let y-cache = -25.2 // decision
  let y-compile = -27.6
  let y-write = -29.8
  let y-mirror = -32.0
  let y-log = -34.2

  // --- Cluster backgrounds (drawn first, behind nodes) ---
  rect((-7.2, y-sys + 1.5), (7.2, y-sys - 1.2), fill: cfill, stroke: (dash: "dashed", paint: cstroke))
  clabel((-7.1, y-sys + 1.5), text(weight: "bold")[Font resolution · resolve_font_paths])

  rect((-2.2, y-key + 0.7), (7.2, y-compile - 1.0), fill: cfill, stroke: (dash: "dashed", paint: cstroke))
  clabel((7.1, y-key + 0.7), text(weight: "bold")[Cache & compile], anchor: "south-east")

  // --- Title ---
  content((0, 1.6), text(15pt, weight: "bold")[social-card extension workflow])
  content((0, 1.0), text(8.5pt, fill: rgb("#555"))[HTML render · Lua `Meta` filter → 1200×630 PNG])

  // --- Spine nodes ---
  node((0, y-html), "html", [Quarto render \ *(HTML format only)*], fill: afill, stroke: astroke)
  node((0, y-opts), "opts", [Read options \ `extensions.social-card` + top-level + `DEFAULTS`])
  decision(0, y-en, [`enabled` \ `== false`?])
  node((0, y-text), "text", [Resolve title / subtitle \ *(subtitle ← description)*])
  node((0, y-mode), "mode", [Resolve brand mode \ *(light / dark)*])
  node((0, y-brand), "brand", [Build context: brand colours + fonts \ `quarto.brand`])
  node((0, y-image), "image", [Resolve image \ *(Typst root-relative path)*])
  node((0, y-source), "source", [Render Typst source \ `template.typ` + context])
  node((0, y-bin), "bin", [Resolve Typst binary \ `quarto.paths.typst`])
  decision(0, y-sys, [Family is a \ system font?])
  node((0, y-key), "key", [Cache key = hash \ source + image + font paths])
  decision(0, y-cache, [Cached PNG \ exists?])
  node((0, y-compile), "compile", [`typst compile` → PNG \ `--ppi 144 --root`], fill: afill, stroke: astroke)
  node((0, y-write), "write", [Write PNG to output path \ `output-dir` / `filename`])
  node((0, y-mirror), "mirror", [Mirror PNG to \ project output directory])
  node((0, y-log), "log", [Log `open-graph` / `twitter-card` \ reference snippet], fill: afill, stroke: astroke)

  // --- Branch nodes ---
  node((5, y-en), "skip", [Stop \ *(no card)*], fill: sfill, stroke: sstroke)
  node((-5, y-sys), "dl", [Download Google faces \ → cache *(sentinel)*])
  node((5, y-sys), "use", [Use installed font \ *(Typst resolves it)*])
  node((5, y-cache), "hit", [Reuse cached PNG])

  // --- Spine arrows ---
  arrow("html.south", "opts.north")
  arrow("opts.south", (0, y-en + dh))
  arrow((0, y-en - dh), "text.north")
  arrow("text.south", "mode.north")
  arrow("mode.south", "brand.north")
  arrow("brand.south", "image.north")
  arrow("image.south", "source.north")
  arrow("source.south", "bin.north")
  arrow("bin.south", (0, y-sys + dh))
  arrow("key.south", (0, y-cache + dh))
  arrow((0, y-cache - dh), "compile.north")
  arrow("compile.south", "write.north")
  arrow("write.south", "mirror.north")
  arrow("mirror.south", "log.north")

  // --- Branch arrows ---
  // enabled? → stop
  arrow((dw, y-en), "skip.west")
  elabel(((dw + 5 - 1.85) / 2, y-en + 0.3), [false])

  // system font? → download (No, left) / use (Yes, right) → cache key
  arrow((-dw, y-sys), "dl.east")
  elabel((-2.5, y-sys + 0.3), [No])
  arrow((dw, y-sys), "use.west")
  elabel((2.5, y-sys + 0.3), [Yes])
  arrow("dl.south", "key.north")
  arrow("use.south", "key.north")

  // cached? → reuse (Yes) bypasses compile / miss continues down
  arrow((dw, y-cache), "hit.west")
  elabel((2.5, y-cache + 0.3), [Yes])
  arrow("hit.south", "write.east")
})
