// =====================================================================
//  ESPuino Box - parametric enclosure
//  Paste into https://ochafik.com/openscad/
//  F5 = fast preview   |   Ctrl+Enter = full render (before STL export)
//
//  All screws are self-tapping directly into printed plastic.
//  No heat-set inserts anywhere.
//
//  PRINT ORIENTATION - SHELL (part = "shell"): top face down on the bed.
//  Every internal post then grows upwards and needs no support. Only the
//  LED ring pocket in the front wall wants a little support.
//
//  PRINT ORIENTATION - LID (part = "lid"): flat, posts facing up. No
//  support needed.
// =====================================================================

/* [Part selection] */
// shell = main body | lid = bottom plate | assembly = both together
part = "shell"; // [shell, lid, assembly]

/* [Overall dimensions] */
box_w    = 120;  // width  (X)
box_d    = 120;  // depth  (Y)
box_h    = 120;  // height (Z)
wall     = 4;    // KEEP <= 5: arcade buttons clip onto 2-5 mm panels only
corner_r = 8;    // vertical edge radius
top_r    = 8;    // top edge radius
bottom_ch = 1.5; // chamfer on the bottom visible rim

/* [Lid and closure] */
lid_t     = 4;     // lid thickness
lid_lip   = 3;     // depth of the rebate the lid drops into
lid_gap   = 0.25;  // fit clearance. Raise to 0.35 if too tight
lid_ch    = 0.6;   // chamfer on the lid's visible bottom edge
post_inset = 7;    // screw centre, measured in from the inner wall face
post_sq    = 15;   // side of the square corner block
post_ch    = 5;    // 45 deg cut on the block's exposed inner corner
post_h     = 14;   // block height above the lid shoulder
m3_tap_d   = 2.5;  // self-tapping M3 into plastic
m3_free_d  = 3.4;  // M3 clearance hole
m3_head_d  = 6.4;  // countersink diameter

/* [Top face - buttons] */
button_hole_d = 24.3;  // Sanwa OBSF-24 / EG STARTS 24 mm snap-in
button_count  = 3;
button_pitch  = 32;    // centre-to-centre. Min ~30, the flange is 28 mm
button_row_y  = 28;    // distance from the front face
button_ch     = 1.5;   // inner chamfer, eases the print and the fitting

/* [Top face - RFID reader, trapezoid hole pattern] */
rfid_span_front = 25;   // X distance between the two front holes
rfid_span_rear  = 35;   // X distance between the two rear holes
rfid_row_gap    = 40;   // Y distance between the rows
rfid_centre_y   = 84;
rfid_post_h     = 5;    // keep short, the reader must stay near the surface
rfid_post_d     = 8;
rfid_post_taper = 2.5;  // 45 deg ramp at the base of each post
rfid_tap_d      = 2.5;  // self-tapping M3

/* [Engraving - general] */
icon_depth = 0.6;   // engraving depth everywhere. 3 layers at 0.2 mm

/* [Engraving - top face] */
icon_size   = 10;    // nominal height of the button icons
icon_stroke = 2.4;   // bar thickness of the + and - icons
icon_row_y  = 47;    // Y position of the button icon row
wave_count  = 3;     // arcs per side
wave_gap    = 5.5;   // radial spacing between arcs
wave_t      = 1.6;   // arc thickness
wave_angle  = 100;   // angular span of each arc
wave_dot_d  = 7.0;   // centre ring outer diameter

/* [Engraving - side walls] */
music_on    = true;
staff_len   = 90;    // staff length, centred along the box depth
staff_space = 5;     // gap between staff lines
staff_t     = 1.2;   // line thickness. Below ~1.0 the slicer struggles
note_size   = 5;     // note head height, matched to staff_space
staff_shift = -3;    // vertical nudge. Negative balances the stems,
                     // which all point up and add visual weight above

/* [Front face - speaker and LED ring, one integrated piece] */
front_centre_z     = 62;
led_ring_id        = 27.0;
ring_seat_d        = 35.4;  // pocket the LED ring drops into, from inside
diffuser_t         = 1.2;   // wall the LEDs shine through. 1.0-1.4
speaker_screw_span = 37;    // centre-to-centre of the two speaker screws
speaker_boss_h     = 5;
speaker_boss_d     = 10;

/* [Front face - honeycomb grille] */
grille_d = 25.5;  // must stay inside led_ring_id
hex_size = 3.0;   // hexagon across-corners size
hex_wall = 1.2;   // material between hexagons

/* [Rear face - connectors] */
usb_w    = 9.2;   // USB-C cutout, sized for the panel-mount USB-C
                  // extension module (amazon.es B0D8SGMGT3) that carries
                  // the TC4056A's port out to this face
usb_h    = 3.6;
usb_x    = 60;
usb_z    = 40;
usbc_screw_span = 17;   // mounting-screw centre-to-centre, per the module's
                        // spec ("distancia entre ejes de 17 mm")
usbc_tap_d      = 1.6;  // self-tapping M2, same convention as mb_tap_d
switch_d = 6.2;
switch_x = 85;
switch_z = 40;

/* [Lid - mainboard posts] */
// Coordinates below are LOCAL TO THE LID, origin at its front-left corner
mb_span_x   = 46;
mb_span_y   = 66;
mb_origin_x = 10;
mb_origin_y = 25;
mb_post_h   = 6;
mb_post_d   = 6;
mb_tap_d    = 1.6;   // self-tapping M2

/* [Lid - battery tie-down lugs] */
// No continuous cage: just 4 standalone corner lugs holding the cell
// down with zip ties, so a different cell footprint can be swapped in
// later without redesigning walls. bat_l/bat_w/bat_clearance still
// describe the envelope the lugs sit around, but nothing physically
// encloses it anymore. Each lug is a plain rectangular post - longer
// along Y than X, for a bigger bonded footprint at the base without
// needing a gusset - with a zip-tie window (bottom flush with the lid
// surface, so all the height above becomes bridge: lug_h - lug_hole_h
// = 7mm). The front pair of lugs anchors one tie, the back pair the
// other (both ties run across X, same as the old 2-strap layout).
bat_l         = 65;   // envelope length, along Y (not a hard wall)
bat_w         = 40;   // envelope width, along X
bat_h         = 12;   // cell thickness, informational: lug_h is set to match
bat_clearance = 2.0;  // lug inset from the nominal cell footprint. DO NOT
                      // reduce: pouch cells swell with age
bat_origin_x  = 62;   // local to the lid
bat_origin_y  = 25;
lug_x         = 5;    // lug footprint, X
lug_y         = 20;   // lug footprint, Y - longer than lug_x on purpose
lug_h         = 12;   // lug height, flush with bat_h
lug_hole_w    = 4;    // zip-tie window width (Y), fits common small/medium ties
lug_hole_h    = 5;    // zip-tie window height (Z), from the lid surface up


/* [Resolution] */
$fn = $preview ? 24 : 72;

// =====================================================================
//  Derived values - do not edit
// =====================================================================
lid_shoulder_z = lid_t + lid_gap;
lid_w      = box_w - 2 * wall + lid_lip - 2 * lid_gap;
lid_d      = box_d - 2 * wall + lid_lip - 2 * lid_gap;
lid_origin = wall - lid_lip / 2 + lid_gap;

// Staff is centred on the wall in both directions
staff_y = (box_d - staff_len) / 2;
staff_z = box_h / 2 - staff_space * 2 + staff_shift;

// Notes on the staff: [position along the staff as a fraction of its
// length, vertical position in staff spaces above the bottom line,
// style 0 = quarter, 1 = eighth, 2 = beamed pair]
NOTES = [
    [0.10, 1.0, 0],
    [0.28, 2.0, 2],
    [0.50, 1.5, 0],
    [0.66, 2.5, 2],
    [0.88, 0.5, 0]
];

function corner_pts() = [
    for (x = [wall + post_inset, box_w - wall - post_inset],
         y = [wall + post_inset, box_d - wall - post_inset]) [x, y]
];

function button_x(i) =
    box_w / 2 + (i - (button_count - 1) / 2) * button_pitch;

function rfid_pts() = [
    [box_w/2 - rfid_span_front/2, rfid_centre_y - rfid_row_gap/2],
    [box_w/2 + rfid_span_front/2, rfid_centre_y - rfid_row_gap/2],
    [box_w/2 - rfid_span_rear/2,  rfid_centre_y + rfid_row_gap/2],
    [box_w/2 + rfid_span_rear/2,  rfid_centre_y + rfid_row_gap/2]
];

// =====================================================================
//  Generic helpers
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

module outer_body(w, d, h, r, rt, ch) {
    union() {
        skirted_box(w, d, h - rt, r, ch);
        translate([0, 0, h - rt])
            hull() for (x = [rt, w - rt], y = [rt, d - rt])
                translate([x, y, 0]) sphere(r = rt);
    }
}

module honeycomb(diameter, thickness) {
    r_hex  = hex_size / 2;
    r_cell = r_hex + hex_wall / sqrt(3);
    dx = 1.5 * r_cell;
    dy = sqrt(3) * r_cell;
    n  = ceil(diameter / min(dx, dy)) + 2;
    intersection() {
        cylinder(h = thickness, d = diameter);
        for (col = [-n : n], row = [-n : n])
            translate([col * dx, row * dy + (col % 2 != 0 ? dy/2 : 0), 0])
                cylinder(h = thickness, r = r_hex, $fn = 6);
    }
}

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
//  2D icons
// =====================================================================

module rounded_bar(w, h, r) {
    offset(r = r) square([w - 2*r, h - 2*r], center = true);
}

module icon_plus(s, t)  { rounded_bar(s, t, t/3); rounded_bar(t, s, t/3); }
module icon_minus(s, t) { rounded_bar(s, t, t/3); }

module icon_play(s) {
    offset(r = 1)
        polygon([[-s*0.28, -s*0.38], [-s*0.28, s*0.38], [s*0.40, 0]]);
}

// Contactless symbol: centre ring plus mirrored arcs on both sides
module icon_rfid(n, gap, t, ang, dot_d) {
    reach = (n * gap + t) * 1.3;
    wedge = concat([[0, 0]],
        [for (a = [-ang/2 : ang/12 : ang/2])
            [reach * cos(a), reach * sin(a)]]);
    difference() {
        circle(d = dot_d);
        circle(d = dot_d - 2 * t);
    }
    for (side = [1, -1])
        scale([side, 1])
            for (i = [1 : n])
                intersection() {
                    difference() {
                        circle(r = i * gap + t/2);
                        circle(r = i * gap - t/2);
                    }
                    polygon(wedge);
                }
}

// --- musical elements, drawn upright with the stem towards +Y --------

module note_head(s) {
    rotate(-20) scale([1.35, 1]) circle(d = s * 0.98, $fn = 28);
}

module note_stem(s, h) {
    translate([s * 0.55, 0]) square([s * 0.22, s * h]);
}

module icon_note_quarter(s) {
    note_head(s);
    note_stem(s, 3.0);
}

module icon_note_eighth(s) {
    icon_note_quarter(s);
    offset(r = s * 0.12)
        polygon([[s*0.72, s*2.85], [s*1.35, s*2.25],
                 [s*1.25, s*1.55], [s*0.85, s*2.10]]);
}

module icon_note_beamed(s) {
    for (dx = [0, s * 1.9])
        translate([dx, 0]) { note_head(s); note_stem(s, 3.0); }
    translate([s * 0.55, s * 2.6])
        square([s * 1.9 + s * 0.22, s * 0.45]);
}

module icon_note(s, style) {
    if      (style == 0) icon_note_quarter(s);
    else if (style == 1) icon_note_eighth(s);
    else                 icon_note_beamed(s);
}

module icon_staff(len, spacing, t, n = 5) {
    for (i = [0 : n - 1]) translate([0, i * spacing]) square([len, t]);
}

// =====================================================================
//  Engraving placement
// =====================================================================

module top_engraving() {
    translate([0, 0, box_h - icon_depth]) linear_extrude(icon_depth + 1) {
        translate([box_w/2, rfid_centre_y])
            icon_rfid(wave_count, wave_gap, wave_t, wave_angle, wave_dot_d);
        // Order follows the buttons left to right, as seen standing in
        // front of the speaker grille: minus, play, plus.
        translate([button_x(0), icon_row_y]) icon_minus(icon_size, icon_stroke);
        translate([button_x(1), icon_row_y]) icon_play(icon_size);
        translate([button_x(2), icon_row_y]) icon_plus(icon_size, icon_stroke);
    }
}

// Authored in normal upright 2D: X runs along the box depth, Y is height.
// No treble clef: a hand-drawn clef path was tried and rejected as
// unrecognizable at this scale. Don't reintroduce without a better source
// (e.g. text() with a font that has a clef glyph, or an imported SVG).
module wall_pattern() {
    translate([staff_y, staff_z]) icon_staff(staff_len, staff_space, staff_t);

    for (n = NOTES)
        translate([staff_y + n[0] * staff_len,
                   staff_z + n[1] * staff_space])
            icon_note(note_size, n[2]);
}

// Maps the upright 2D pattern onto the left wall (X = 0)
module wall_art_left() {
    translate([icon_depth, 0, 0]) rotate([0, -90, 0])
        linear_extrude(icon_depth + 1)
            // local X becomes world Z, local Y becomes world Y
            rotate(-90) scale([-1, 1]) wall_pattern();
}

// The right wall is a mirror of the whole thing, so both read correctly
// when viewed from outside. Rotating instead would flip the artwork.
module side_engraving() {
    if (music_on) {
        wall_art_left();
        translate([box_w, 0, 0]) mirror([1, 0, 0]) wall_art_left();
    }
}

// =====================================================================
//  Shell
// =====================================================================

module corner_block(s, c, h) {
    linear_extrude(h)
        polygon([[0, 0], [s, 0], [s, s - c], [s - c, s], [0, s]]);
}

module corner_post_solid() {
    difference() {
        translate([wall, wall, lid_shoulder_z])
            corner_block(post_sq, post_ch, post_h);
        translate([wall + post_inset, wall + post_inset,
                   lid_shoulder_z - lid_t - 1])
            cylinder(h = post_h + lid_t + 1, d = m3_tap_d);
    }
}

module corner_posts() {
    for (mx = [0, 1], my = [0, 1])
        translate([mx * box_w, my * box_d, 0])
            scale([mx ? -1 : 1, my ? -1 : 1, 1])
                corner_post_solid();
}

module rfid_posts() {
    for (p = rfid_pts())
        translate([p[0], p[1], box_h - wall - rfid_post_h])
            post(rfid_post_h, rfid_post_d, rfid_tap_d, rfid_post_taper);
}

// Two bosses that hold the speaker. Their pilot holes sit ~0.45 mm
// inside the ring pocket edge. That sliver is intentional: it is what
// lets a 37 mm screw span clear a 35 mm ring. The bosses are trimmed
// flush with the pocket wall so the ring still seats.
module speaker_bosses() {
    translate([box_w/2, wall, front_centre_z]) rotate([-90, 0, 0])
        difference() {
            for (s = [-1, 1])
                translate([0, s * speaker_screw_span / 2, 0])
                    post(speaker_boss_h, speaker_boss_d, m3_tap_d);
            translate([0, 0, -0.01])
                cylinder(h = speaker_boss_h + 0.02, d = ring_seat_d);
        }
}

module shell_cutouts() {
    // FRONT: ring pocket from the inside, honeycomb through the middle
    translate([box_w/2, 0, front_centre_z]) rotate([-90, 0, 0]) {
        translate([0, 0, diffuser_t])
            cylinder(h = wall - diffuser_t + 0.01, d = ring_seat_d);
        translate([0, 0, -1]) honeycomb(grille_d, wall + 2);
    }

    // TOP: button holes with an inner chamfer
    for (i = [0 : button_count - 1]) {
        translate([button_x(i), button_row_y, box_h - wall - 1]) {
            cylinder(h = wall + 2, d = button_hole_d);
            translate([0, 0, 1 - 0.01])
                cylinder(h = button_ch,
                         d1 = button_hole_d + 2 * button_ch,
                         d2 = button_hole_d);
        }
    }

    top_engraving();
    side_engraving();

    // REAR: USB-C and power switch
    translate([usb_x - usb_w/2, box_d - wall - 1, usb_z])
        cube([usb_w, wall + 2, usb_h]);
    // USB-C module mounting screws, flanking the port cutout, level with
    // its vertical centre (usb_z is the cutout's bottom edge, not its
    // middle - the cube's origin is a corner, not a centre)
    for (s = [-1, 1])
        translate([usb_x + s * usbc_screw_span / 2, box_d - wall - 1,
                    usb_z + usb_h / 2])
            rotate([-90, 0, 0]) cylinder(h = wall + 2, d = usbc_tap_d);
    translate([switch_x, box_d - wall - 1, switch_z])
        rotate([-90, 0, 0]) cylinder(h = wall + 2, d = switch_d);

    // BOTTOM: rebate the lid drops into
    translate([wall - lid_lip/2, wall - lid_lip/2, -0.01])
        rounded_box(box_w - 2*wall + lid_lip, box_d - 2*wall + lid_lip,
                    lid_shoulder_z, corner_r);
}

module shell() {
    difference() {
        union() {
            difference() {
                outer_body(box_w, box_d, box_h, corner_r, top_r, bottom_ch);
                translate([wall, wall, -1])
                    rounded_box(box_w - 2*wall, box_d - 2*wall,
                                box_h - wall + 1, max(corner_r - wall, 1));
            }
            corner_posts();
            rfid_posts();
            speaker_bosses();
        }
        shell_cutouts();
    }
}

// =====================================================================
//  Lid
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
            post(mb_post_h, mb_post_d, mb_tap_d);
}

// Canonical lug: assumes it sits at the MIN-X,MIN-Y corner of the
// envelope, extending toward +X,+Y (where the cell is). Other corners
// reuse this via mirroring - see battery_lugs().
module battery_lug_canonical() {
    difference() {
        cube([lug_x, lug_y, lug_h]);
        // Zip-tie window, bored straight through in X, flush with the
        // lid surface (z=0 here) so all the height above is bridge.
        translate([-0.01, lug_y/2 - lug_hole_w/2, 0])
            cube([lug_x + 0.02, lug_hole_w, lug_hole_h]);
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
        for (p = corner_pts())
            translate([p[0] - lid_origin, p[1] - lid_origin, -0.01]) {
                cylinder(h = lid_t + 1, d = m3_free_d);
                cylinder(h = (m3_head_d - m3_free_d) / 2 + 0.4,
                         d1 = m3_head_d, d2 = m3_free_d);
            }
    }
}

// =====================================================================
//  Output
// =====================================================================
if (part == "shell")    shell();
else if (part == "lid") lid();
else {
    shell();
    translate([lid_origin, lid_origin, lid_gap]) lid();
}
