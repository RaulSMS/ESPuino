// =====================================================================
//  ESPuino Box - LID (separate file, printed on its own)
//  Paste into https://ochafik.com/openscad/
//  F5 = fast preview   |   Ctrl+Enter = full render (before STL export)
//
//  All screws are self-tapping directly into printed plastic.
//
//  PRINT ORIENTATION: flat, posts facing up. No support needed.
//
//  *** KEEP IN SYNC WITH THE SHELL FILE ***
//  The six values in the block below must match the shell file
//  exactly, or the lid will not fit the rebate / the screws will not
//  line up with the shell's corner posts. If you change wall,
//  box_w, box_d, lid_lip, lid_gap or post_inset in the shell file,
//  copy the new values here too.
// =====================================================================

/* [Must match the shell file] */
box_w      = 120;  // shell width  (X)
box_d      = 120;  // shell depth  (Y)
wall       = 4;    // shell wall thickness
lid_lip    = 3;    // depth of the rebate the lid drops into
lid_gap    = 0.25; // fit clearance, same value as in the shell
post_inset = 7;    // shell corner-post screw centre, in from inner wall

/* [Lid] */
lid_t   = 4;     // lid thickness
lid_ch  = 0.6;   // chamfer on the visible bottom edge
corner_r = 8;    // must match the shell's corner_r for the fit to look right

/* [Closing screws - 4 corners, into the shell's posts] */
m3_free_d = 3.4;  // M3 clearance hole
m3_head_d = 6.4;  // countersink diameter

/* [Mainboard posts - all 4 corners of a rectangle] */
mb_span_x   = 46;   // X centre-to-centre
mb_span_y   = 66;   // Y centre-to-centre
mb_origin_x = 10;   // pattern origin, local to the lid
mb_origin_y = 20;
mb_post_h   = 6;
mb_post_d   = 6;
mb_hole_d   = 2.0;  // through-hole in each post

/* [Battery tie-down lugs] */
// No continuous cage: just 4 standalone corner lugs holding the cell
// down with zip ties, so a different cell footprint can be swapped in
// later without redesigning walls. bat_l/bat_w/bat_clearance still
// describe the envelope the lugs sit around, but nothing physically
// encloses it anymore. Each lug is a square post with a zip-tie window
// (bottom flush with the lid surface, so all the height above becomes
// bridge: lug_h - lug_hole_h = 7mm) plus a triangular gusset flaring
// the base outward, on the two faces that face away from the cell - a
// standalone post takes the tie's inward pull alone, without a
// continuous wall to spread it across, so it needs its own bracing.
// The front pair of lugs anchors one tie, the back pair the other
// (both ties run across X, same as the old 2-strap layout).
// gusset_l = 4mm was chosen to keep clear of the mainboard posts
// (mb_origin_x/y above) by a couple of mm - re-check by hand if
// mb_span_x/y or bat_origin_x/y ever move.
bat_l         = 65;   // envelope length, along Y (not a hard wall)
bat_w         = 35;   // envelope width, along X
bat_h         = 12;   // cell thickness, informational: lug_h is set to match
bat_clearance = 2.0;  // lug inset from the nominal cell footprint. DO NOT
                      // reduce: pouch cells swell with age
bat_origin_x  = 64;   // local to the lid
bat_origin_y  = 18;
lug_sq        = 8;    // lug cross-section, square
lug_h         = 12;   // lug height, flush with bat_h
lug_hole_w    = 4;    // zip-tie window width (Y), fits common small/medium ties
lug_hole_h    = 5;    // zip-tie window height (Z), from the lid surface up
gusset_l      = 4;    // gusset reach, outward from the lug along each axis

/* [Resolution] */
$fn = $preview ? 24 : 72;

// =====================================================================
//  Derived values - do not edit
// =====================================================================
lid_w      = box_w - 2 * wall + lid_lip - 2 * lid_gap;
lid_d      = box_d - 2 * wall + lid_lip - 2 * lid_gap;
lid_origin = wall - lid_lip / 2 + lid_gap;

// Same formula as corner_pts() in the shell file, re-expressed in the
// lid's own coordinate system (shell coords minus lid_origin)
function corner_pts_local() = [
    for (x = [wall + post_inset - lid_origin,
              box_w - wall - post_inset - lid_origin],
         y = [wall + post_inset - lid_origin,
              box_d - wall - post_inset - lid_origin]) [x, y]
];

// =====================================================================
//  Helpers
// =====================================================================

module rounded_box(w, d, h, r) {
    hull() for (x = [r, w - r], y = [r, d - r])
        translate([x, y, 0]) cylinder(h = h, r = r);
}

module skirted_box(w, d, h, r, ch) {
    union() {
        hull() {
            translate([ch, ch, 0])
                rounded_box(w - 2*ch, d - 2*ch, 0.01, max(r - ch, 0.5));
            translate([0, 0, ch]) rounded_box(w, d, 0.01, r);
        }
        translate([0, 0, ch]) rounded_box(w, d, h - ch, r);
    }
}

// Post with a tapered foot so it prints without support
module post(height, outer_d, hole_d, taper = 1.5) {
    difference() {
        union() {
            cylinder(h = taper, d1 = outer_d + 2*taper, d2 = outer_d);
            cylinder(h = height, d = outer_d);
        }
        translate([0, 0, -0.01]) cylinder(h = height + 0.02, d = hole_d);
    }
}

// =====================================================================
//  Features
// =====================================================================

module mainboard_posts() {
    pts = [
        [mb_origin_x,             mb_origin_y],
        [mb_origin_x + mb_span_x, mb_origin_y],
        [mb_origin_x,             mb_origin_y + mb_span_y],
        [mb_origin_x + mb_span_x, mb_origin_y + mb_span_y]
    ];
    for (i = [0 : 3])
        translate([pts[i][0], pts[i][1], lid_t])
            post(mb_post_h, mb_post_d, mb_hole_d);
}

// Canonical lug: assumes it sits at the MIN-X,MIN-Y corner of the
// envelope, so the cell is toward +X,+Y from here and "outward" (where
// the gusset flares, and where nothing needs to clear the cell) is
// -X,-Y. Other corners reuse this via mirroring - see battery_lugs().
module battery_lug_canonical() {
    difference() {
        linear_extrude(lug_h)
            polygon([
                [-gusset_l, 0], [lug_sq, 0], [lug_sq, lug_sq],
                [0, lug_sq], [0, -gusset_l]
            ]);
        // Zip-tie window, bored straight through in X, flush with the
        // lid surface (z=0 here) so all the height above is bridge.
        translate([-0.01, lug_sq/2 - lug_hole_w/2, 0])
            cube([lug_sq + 0.02, lug_hole_w, lug_hole_h]);
    }
}

module battery_lugs() {
    ow = bat_w + 2 * bat_clearance;
    ol = bat_l + 2 * bat_clearance;
    // [x, y, mirror-x, mirror-y] for each of the 4 envelope corners
    corners = [
        [bat_origin_x,      bat_origin_y,       1,  1],
        [bat_origin_x + ow, bat_origin_y,      -1,  1],
        [bat_origin_x,      bat_origin_y + ol,  1, -1],
        [bat_origin_x + ow, bat_origin_y + ol, -1, -1],
    ];
    for (c = corners)
        translate([c[0], c[1], lid_t])
            scale([c[2], c[3], 1])
                battery_lug_canonical();
}

module lid() {
    difference() {
        union() {
            skirted_box(lid_w, lid_d, lid_t, corner_r, lid_ch);
            mainboard_posts();
            battery_lugs();
        }
        // 4 countersunk M3 clearance holes, aligned with the shell's
        // corner posts so the lid screws straight into them
        for (p = corner_pts_local())
            translate([p[0], p[1], -0.01]) {
                cylinder(h = lid_t + 1, d = m3_free_d);
                cylinder(h = (m3_head_d - m3_free_d) / 2 + 0.4,
                         d1 = m3_head_d, d2 = m3_free_d);
            }
    }
}

lid();
