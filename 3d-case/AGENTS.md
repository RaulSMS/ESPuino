# 3D Case (OpenSCAD) — Agent Notes

Scope: the printable enclosure in this directory only. This is a mechanical CAD side-project living
inside the ESPuino firmware repo, not firmware work — the root `AGENTS.md` (build system, C++
architecture, FreeRTOS, HAL layering, etc.) does not apply here and shouldn't be pulled into this
context. The only thing carried over from there is which physical modules the case has to fit, listed
below.

## Files

- `espuino_box.scad` — the shell (walls, top/front/rear faces). `part` parameter selects `"shell"`,
  `"lid"`, or `"assembly"` (both together) for preview.
- `espuino_lid.scad` — bottom plate, printed separately. Duplicates a handful of dimensions that must
  stay in sync with the shell file; the sync-block list and why it exists are documented at the top of
  `espuino_lid.scad` itself.

Both files are self-documenting: every parameter has an inline comment carrying its value, rationale,
and constraints (e.g. `wall`'s 5mm cap for button snap-fit, `bat_clearance`'s "do not reduce, pouch
cells swell"). **Treat the `.scad` files as the single source of truth for current dimensions and
design decisions — don't restate them here.** A second copy in this doc would just drift out of sync
as the design iterates. If something needs to persist *across sessions* but isn't a stable convention
(an open verification question, a rejected approach, a fit-test result), save it as a **project
memory** instead of adding it to this file — memory is read on demand when relevant, this file gets
read every time work touches this directory.

## Hardware this has to fit (sourcing only — dimensions live in the `.scad` files)

| Component | Source |
|---|---|
| MCU | ESP32-S3-DevKitC-1 (N16R8) |
| RFID reader | MFRC522, trapezoid hole pattern — amazon.es B0G6JRLWN1 |
| Buttons | 3x EG STARTS 24mm arcade, Sanwa OBSF-24 compatible — amazon.es B075DCB7LT |
| LED ring | 12x WS2812B |
| Charging | TC4056A module (USB-C) |

## Toolchain

- OpenSCAD, edited as code — no GUI modeling.
- Preview/render: https://ochafik.com/openscad/ (WASM, no install, Manifold backend). F5 = fast
  preview, Ctrl+Enter = full render. Both files set `$fn = $preview ? 24 : 72` — preview is
  deliberately coarser, so re-check geometry after a full render before trusting it for slicing,
  especially small features like engraving or lattices.
- Units: mm throughout.
- Comments and all text in the files: English.

## General OpenSCAD rules worth following here

- The Manifold backend (default in recent OpenSCAD, and what the online playground uses) makes CSG
  ops themselves fast — the cost is in mesh evaluation (render/export), so avoid triggering that
  needlessly mid-iteration.
- Keep `$fn` low while iterating and only raise it for final render/export. High `$fn` combined with
  `hull()`/`minkowski()` is the classic multi-minute-compile trap — `minkowski()` cost scales with the
  *product* of both operands' segment counts, not the sum (e.g. two `$fn=100` cylinders → ~10,000
  operations).
- For rounded boxes/plates, prefer 2D `offset()` + `linear_extrude()` over 3D `minkowski()` with a
  sphere — same result, orders of magnitude faster. Reserve true 3D `minkowski()` for sweeping a
  profile along a genuinely 3D path.
- If a module ever drops to raw `polyhedron()`, face vertex winding must be clockwise as seen from
  outside, or you get inverted normals / non-manifold warnings. Not currently relevant — everything
  here builds from primitives + CSG — but the first thing to check if it comes up.
- STL is fine for slicer handoff, but it's a lossy triangle-soup format; if exporting for anything
  other than immediate slicing, 3MF preserves more.

## Print-process conventions already baked into both files

- No heat-set inserts — screws self-tap directly into printed plastic (pilot-hole sizing is in the
  parameter comments, per-screw).
- Print orientation and support strategy are called out in each file's own header comment — check
  there before assuming both parts print the same way up.
