# ESPuino 3D-printed case

Parametric OpenSCAD enclosure for this project. Two files, printed separately:

- `espuino_box.scad` — the shell (also contains an internal copy of the lid, for
  the `assembly` preview — see below).
- `espuino_lid.scad` — the bottom plate, as a standalone file so it can be
  pasted into the online renderer on its own without dragging the shell along.

## Getting the tools

- **Desktop app** (for full renders / STL export): download OpenSCAD from
  <https://openscad.org/downloads.html>.
- **No-install online renderer**: <https://ochafik.com/openscad/> (WASM build,
  Manifold backend — this is what was used to design and preview this case).
  Paste a `.scad` file's contents in, press F5 for a fast preview or
  Ctrl+Enter for a full render before exporting STL.

## Working with these files (with or without AI help)

Every parameter lives at the top of each file with an inline comment
explaining its value and *why* it's set that way (tolerances, screw types,
print constraints, etc.) — read those comments before changing a number, and
update them if you change it. The `.scad` files are the single source of
truth for current dimensions; don't trust older chat logs or docs over what's
actually in the file.

If you're using an AI coding assistant (Claude Code, ChatGPT, etc.) to modify
this case:

- Point it at this directory specifically — the rest of the ESPuino repo is
  firmware (C++/PlatformIO) and is unrelated to this mechanical design.
- Ask it to state the change in plain terms first (what dimension/feature
  moves, why) before editing, and to check for collisions with nearby
  geometry (posts, ribs, screw holes) — OpenSCAD won't warn you about parts
  that silently overlap or barely clear each other.
- Preview (F5) after every change. Full-render (Ctrl+Enter) before trusting
  it enough to export an STL — small features (engraving, lattices, tight
  clearances) can look fine in the coarser preview and only show problems at
  full resolution.
- No test print has replaced a real fit-check yet — treat any change to a
  screw hole, snap-fit, or clearance as unverified until it's been printed
  and tried against the real part.

Print-process specifics (orientation, supports, screw types) are documented
in each file's own header comment.
