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

/* [Mainboard posts - 3 corners of a rectangle] */
mb_span_x   = 46;   // X centre-to-centre
mb_span_y   = 66;   // Y centre-to-centre
mb_origin_x = 10;   // pattern origin, local to the lid
mb_origin_y = 20;
mb_post_h   = 6;
mb_post_d   = 6;
mb_hole_d   = 2.0;  // through-hole in each post
// Which corner of the rectangle has NO post.
// 0 = front-left, 1 = front-right, 2 = rear-left, 3 = rear-right
mb_skip_corner = 3;

/* [Battery cradle - flat LiPo, 65 x 12 x 35 mm] */
bat_l         = 65;   // length, along Y
bat_w         = 35;   // width, along X
bat_h         = 12;   // thickness (not used for the open cradle height)
bat_clearance = 2.0;  // gap on every side. DO NOT reduce: pouch cells
                      // swell with age and must never be compressed
bat_origin_x  = 64;   // local to the lid
bat_origin_y  = 18;
bat_rib_t     = 2.5;  // cradle wall thickness
bat_rib_h     = 8;    // cradle wall height

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
    for (i = [0 : 3]) if (i != mb_skip_corner)
        translate([pts[i][0], pts[i][1], lid_t])
            post(mb_post_h, mb_post_d, mb_hole_d);
}

// Open cradle: four short ribs with clearance all round. The cell is
// located laterally but never squeezed, and nothing sharp touches it.
module battery_cradle() {
    ow = bat_w + 2 * bat_clearance;
    ol = bat_l + 2 * bat_clearance;
    for (dx = [0, ow + bat_rib_t])
        translate([bat_origin_x + dx - bat_rib_t, bat_origin_y, lid_t])
            cube([bat_rib_t, ol, bat_rib_h]);
    for (dy = [0, ol + bat_rib_t])
        translate([bat_origin_x - bat_rib_t,
                   bat_origin_y + dy - bat_rib_t, lid_t])
            cube([ow + 2 * bat_rib_t, bat_rib_t, bat_rib_h]);
}

module lid() {
    difference() {
        union() {
            skirted_box(lid_w, lid_d, lid_t, corner_r, lid_ch);
            mainboard_posts();
            battery_cradle();
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
