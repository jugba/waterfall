class_name Look
extends RefCounted
## Greybox drawing: every creature is a few rounded shapes with big expressive eyes, drawn with
## CanvasItem draw_* calls (no art files). Used by the arena and the title screen.

const PLAYER := Color("4fd8c8")
const PLAYER_BELLY := Color("b8fff2")
const PLAYER_DARK := Color("1f7f86")
const LINE := Color("fff1c1")
const LURE := Color("fff27a")
const EYE_DARK := Color("10131f")
const MOUTH := Color("5a1030")
const TRAIT_COLORS := {"armour": Color("8fa3c2"), "speed": Color("ffd166"), "damage": Color("ff5d73"),
	"pierce": Color("c77dff")}
const TRAIT_NAMES := {"armour": "ARMOUR", "speed": "SPEED", "damage": "POWER", "pierce": "PIERCE"}
const KIND_COLORS := {"nibbler": Color("ff8fa3"), "darter": Color("ffd166"), "shellback": Color("8ab17d"),
	"spitter": Color("c77dff"), "puffer": Color("ff9f1c"), "boss": Color("5a2f7a")}
const ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]

static var _glow_tex: GradientTexture2D


static func glow_texture() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.45))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 64
		_glow_tex.height = 64
	return _glow_tex


static func glow(ci: CanvasItem, pos: Vector2, radius: float, color: Color) -> void:
	ci.draw_texture_rect(glow_texture(), Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)


static func ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color, n := 24) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, color)


static func tri(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([a, b, c]), color)


## Eyes in the current transform. look: unit-ish vector in local space. mode: normal|happy|hurt|angry|wide|closed
static func eye(ci: CanvasItem, at: Vector2, r: float, look: Vector2, mode := "normal", flip := 1.0) -> void:
	match mode:
		"happy":
			ci.draw_arc(at, r * 0.7, PI * 1.1, PI * 1.9, 8, EYE_DARK, r * 0.35, true)
			return
		"hurt":
			var d := r * 0.6
			ci.draw_line(at + Vector2(-d, -d), at + Vector2(d, d), EYE_DARK, r * 0.35, true)
			ci.draw_line(at + Vector2(-d, d), at + Vector2(d, -d), EYE_DARK, r * 0.35, true)
			return
		"closed":
			ci.draw_line(at + Vector2(-r * 0.8, 0), at + Vector2(r * 0.8, 0), EYE_DARK, r * 0.3, true)
			return
	ci.draw_circle(at, r, Color.WHITE)
	var pr := r * (0.55 if mode != "wide" else 0.38)
	ci.draw_circle(at + look.limit_length(1.0) * (r - pr) * 0.8, pr, EYE_DARK)
	ci.draw_circle(at + look.limit_length(1.0) * (r - pr) * 0.8 + Vector2(-pr * 0.35, -pr * 0.35), pr * 0.3, Color(1, 1, 1, 0.9))
	if mode == "angry":
		ci.draw_line(at + Vector2(-r, -r * 0.9 * flip), at + Vector2(r, -r * 0.35 * flip), EYE_DARK, r * 0.35, true)


# =============================================================================
# the player: "Morsel", a little glowing blob whose lure is its hook
# =============================================================================

## o: {mouth: 0..1, eyes: mode, look: Vector2 (local), traits: {armour: lvl ...}, lure: bool, t: time, hurt: 0..1}
static func draw_morsel(ci: CanvasItem, pos: Vector2, r: float, angle: float, squash: Vector2, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var tr: Dictionary = o.get("traits", {})
	# soft shadow (unrotated)
	ci.draw_set_transform(pos + Vector2(r * 0.12, r * 0.28), 0.0, Vector2(squash.x, squash.y * 0.6))
	ci.draw_circle(Vector2.ZERO, r * 1.02, Color(0, 0, 0, 0.28))
	ci.draw_set_transform(pos, angle, squash)
	var arm: int = tr.get("armour", 0)
	var spd: int = tr.get("speed", 0)
	var dmg: int = tr.get("damage", 0)
	var prc: int = tr.get("pierce", 0)
	# speed: fins (behind the body), alternating sides, a tail fin from level 1
	if spd > 0:
		var wag := sin(t * 10.0) * 0.25
		tri(ci, Vector2(-r * 0.8, 0), Vector2(-r * 1.55, -r * (0.45 + wag)), Vector2(-r * 1.55, r * (0.45 - wag)), TRAIT_COLORS["speed"])
		for i in spd - 1:
			var side := 1.0 if i % 2 == 0 else -1.0
			var a := (1.85 + 0.28 * int(i / 2.0)) * side
			var base := Vector2.from_angle(a) * r * 0.85
			var tip := Vector2.from_angle(a + 0.35 * side) * r * 1.45
			tri(ci, base + Vector2.from_angle(a + PI * 0.5) * r * 0.22, base - Vector2.from_angle(a + PI * 0.5) * r * 0.22, tip, TRAIT_COLORS["speed"].darkened(0.1))
	# pierce: spines along the back
	for i in prc * 2:
		var a := PI + (i - (prc * 2 - 1) * 0.5) * 0.3
		var d := Vector2.from_angle(a)
		tri(ci, d.rotated(0.12) * r * 0.9, d.rotated(-0.12) * r * 0.9, d * r * 1.45, TRAIT_COLORS["pierce"])
	# armour: plates on the back half
	for i in arm:
		var a := PI + (i - (arm - 1) * 0.5) * 0.55
		ci.draw_circle(Vector2.from_angle(a) * r * 0.62, r * 0.5, TRAIT_COLORS["armour"].darkened(0.25))
		ci.draw_circle(Vector2.from_angle(a) * r * 0.62, r * 0.42, TRAIT_COLORS["armour"])
	# body
	var hurt: float = o.get("hurt", 0.0)
	var body := PLAYER.lerp(Color("ff5d73"), hurt)
	ci.draw_circle(Vector2.ZERO, r, PLAYER_DARK.lerp(Color("7a1f2b"), hurt))
	ci.draw_circle(Vector2(-r * 0.04, -r * 0.04), r * 0.94, body)
	ci.draw_circle(Vector2(r * 0.18, 0), r * 0.62, PLAYER_BELLY.lerp(body, 0.45))
	ci.draw_circle(Vector2(-r * 0.35, -r * 0.45), r * 0.2, Color(1, 1, 1, 0.35))
	# armour plates also wrap the top as the level rises
	if arm >= 3:
		ci.draw_arc(Vector2.ZERO, r * 0.96, PI * 0.6, PI * 1.4, 16, TRAIT_COLORS["armour"], r * 0.12, true)
	# damage: horns
	for i in mini(dmg, 6):
		var side := 1.0 if i % 2 == 0 else -1.0
		var a := (0.75 + 0.3 * int(i / 2.0)) * side
		var base := Vector2.from_angle(a) * r * 0.85
		var tip := Vector2.from_angle(a * 0.8) * r * (1.35 + 0.08 * dmg)
		tri(ci, base + Vector2.from_angle(a + PI * 0.5) * r * 0.16, base - Vector2.from_angle(a + PI * 0.5) * r * 0.16, tip, Color("fff4e0"))
	# mouth (front): opens while reeling, snaps on a chomp
	var m: float = o.get("mouth", 0.0)
	var mx := r * 0.66
	var mh := r * (0.06 + 0.42 * m)
	ellipse(ci, Vector2(mx, 0), r * (0.2 + 0.12 * m), mh, MOUTH, 16)
	if dmg > 0 and m > 0.15:
		for i in 3:
			var y := (i - 1) * mh * 0.55
			tri(ci, Vector2(mx - r * 0.12, y - r * 0.06), Vector2(mx - r * 0.12, y + r * 0.06), Vector2(mx + r * 0.05, y), Color.WHITE)
	# eyes look toward the aim
	var look: Vector2 = o.get("look", Vector2.RIGHT)
	var mode: String = o.get("eyes", "normal")
	eye(ci, Vector2(r * 0.22, -r * 0.42), r * 0.27, look, mode, 1.0)
	eye(ci, Vector2(r * 0.22, r * 0.42), r * 0.27, look, mode, -1.0)
	# lure: a little glowing bulb on a stalk in front; it *is* the hook, so it's gone while thrown
	if o.get("lure", true):
		var tip := Vector2(r * 1.25, sin(t * 3.0) * r * 0.08)
		ci.draw_line(Vector2(r * 0.85, 0), tip, PLAYER_DARK, maxf(2.0, r * 0.08), true)
		ci.draw_circle(tip, r * 0.16, LURE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func lure_tip(pos: Vector2, r: float, angle: float) -> Vector2:
	return pos + Vector2.from_angle(angle) * r * 1.25


## The hook head: a curved barb with a glowing bulb.
static func draw_hook_head(ci: CanvasItem, pos: Vector2, dir: Vector2, s: float) -> void:
	var a := dir.angle()
	ci.draw_set_transform(pos, a, Vector2.ONE * s)
	ci.draw_arc(Vector2(-4, 0), 8.0, -PI * 0.5, PI * 0.9, 12, LINE, 3.5, true)
	tri(ci, Vector2(-11, 3), Vector2(-6, 9), Vector2(-13, 9), LINE)
	ci.draw_circle(Vector2(5, 0), 4.5, LURE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# =============================================================================
# enemies
# =============================================================================

## v: {flash: 0..1, pop: 0..1 spawn scale, t: time, hookable: bool, open: bool, player: Vector2}
static func draw_enemy(ci: CanvasItem, e, v: Dictionary) -> void:
	var t: float = v.get("t", 0.0)
	var r: float = e.radius * float(v.get("pop", 1.0))
	var pos: Vector2 = e.pos
	var hooked: bool = e.state == ArenaSim.EState.HOOKED
	var stunned: bool = e.state == ArenaSim.EState.STUNNED
	if hooked:
		pos += Vector2(sin(t * 61.0), cos(t * 53.0)) * r * 0.07
	if e.tell > 0.0:
		pos += Vector2(sin(t * 80.0), 0).rotated(e.facing) * r * 0.06
	var heading: float = e.vel.angle() if e.vel.length() > 5.0 else (v.get("player", pos + Vector2.RIGHT) - pos).angle()
	var to_player: Vector2 = (v.get("player", pos) - pos).normalized()
	var col: Color = KIND_COLORS[e.kind]
	var flash: float = v.get("flash", 0.0)
	col = col.lerp(Color.WHITE, flash)
	var eyes := "wide" if hooked else ("angry" if e.tell > 0.0 or (e.kind == "puffer" and e.spiky) else "normal")
	if stunned:
		eyes = "closed"
	# shadow
	ci.draw_set_transform(pos + Vector2(r * 0.1, r * 0.3), 0.0, Vector2(1.0, 0.6))
	ci.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.25))
	match e.kind:
		"nibbler":
			ci.draw_set_transform(pos, heading, Vector2(1.0 + 0.06 * sin(t * 9.0), 1.0 - 0.06 * sin(t * 9.0)))
			var wag := sin(t * 12.0 + e.id) * 0.3
			tri(ci, Vector2(-r * 0.7, 0), Vector2(-r * 1.5, -r * (0.6 + wag)), Vector2(-r * 1.5, r * (0.6 - wag)), col.darkened(0.2))
			ci.draw_circle(Vector2.ZERO, r, col)
			ci.draw_circle(Vector2(r * 0.15, r * 0.2), r * 0.55, col.lightened(0.25))
			eye(ci, Vector2(r * 0.35, -r * 0.15), r * 0.4, Vector2.RIGHT, eyes)
		"darter":
			var stretch := 1.6 if e.dashing > 0.0 else 1.35
			ci.draw_set_transform(pos, heading if e.dashing <= 0.0 else e.dash_dir.angle(), Vector2(stretch, 0.72))
			ci.draw_circle(Vector2.ZERO, r, col)
			tri(ci, Vector2(r * 0.8, -r * 0.4), Vector2(r * 0.8, r * 0.4), Vector2(r * 1.5, 0), col.darkened(0.15))
			tri(ci, Vector2(-r * 0.8, 0), Vector2(-r * 1.4, -r * 0.7), Vector2(-r * 1.2, 0), col.darkened(0.3))
			tri(ci, Vector2(-r * 0.8, 0), Vector2(-r * 1.4, r * 0.7), Vector2(-r * 1.2, 0), col.darkened(0.3))
			eye(ci, Vector2(r * 0.4, -r * 0.35), r * 0.32, Vector2.RIGHT, eyes)
			eye(ci, Vector2(r * 0.4, r * 0.35), r * 0.32, Vector2.RIGHT, eyes, -1.0)
		"shellback":
			var open: bool = v.get("open", false)
			ci.draw_set_transform(pos, e.facing, Vector2.ONE)
			ci.draw_circle(Vector2.ZERO, r * 0.92, col)
			ci.draw_circle(Vector2(-r * 0.2, 0), r * 0.5, col.lightened(0.15))
			eye(ci, Vector2(r * 0.25, -r * 0.35), r * 0.24, Vector2.RIGHT, eyes)
			eye(ci, Vector2(r * 0.25, r * 0.35), r * 0.24, Vector2.RIGHT, eyes, -1.0)
			if open:
				ellipse(ci, Vector2(r * 0.6, 0), r * 0.3, r * 0.35, MOUTH)
			# front shell: a thick armoured arc (lifts back when it opens to bite)
			var cone := deg_to_rad(130.0) * 0.5
			var lift := 0.55 if open else 1.0
			var inner := r * (0.78 if not open else 0.95)
			var outer := r * (1.18 if not open else 1.3)
			var pts := PackedVector2Array()
			var steps := 14
			for i in steps + 1:
				pts.append(Vector2.from_angle(-cone * lift + 2.0 * cone * lift * i / steps + (PI * 0.25 if open else 0.0)) * outer)
			for i in range(steps, -1, -1):
				pts.append(Vector2.from_angle(-cone * lift + 2.0 * cone * lift * i / steps + (PI * 0.25 if open else 0.0)) * inner)
			ci.draw_colored_polygon(pts, Color("5c677d").lerp(Color.WHITE, flash))
			ci.draw_polyline(pts, Color("2b3140"), maxf(1.5, r * 0.06), true)
		"spitter":
			var swell := 1.0 + (0.18 if e.tell > 0.0 else 0.04 * sin(t * 4.0 + e.id))
			ci.draw_set_transform(pos, 0.0, Vector2(swell, swell))
			for i in 5:
				var x := (i - 2) * r * 0.35
				var pts := PackedVector2Array()
				for j in 6:
					pts.append(Vector2(x + sin(t * 5.0 + i + j * 0.9) * r * 0.12, r * 0.4 + j * r * 0.18))
				ci.draw_polyline(pts, col.darkened(0.2), maxf(1.5, r * 0.1), true)
			ellipse(ci, Vector2(0, -r * 0.05), r, r * 0.8, Color(col, 0.92))
			ellipse(ci, Vector2(0, -r * 0.25), r * 0.6, r * 0.4, col.lightened(0.3))
			eye(ci, Vector2(-r * 0.3, -r * 0.1), r * 0.24, to_player, eyes)
			eye(ci, Vector2(r * 0.3, -r * 0.1), r * 0.24, to_player, eyes, -1.0)
		"puffer":
			var sp: bool = e.spiky
			var rr := r * (1.15 if sp else 0.9)
			ci.draw_set_transform(pos, t * (0.4 if sp else 0.1), Vector2.ONE)
			var n := 14
			for i in n:
				var a := TAU * i / n
				var d := Vector2.from_angle(a)
				var len := rr * (1.45 if sp else 1.08)
				tri(ci, d.rotated(0.13) * rr * 0.9, d.rotated(-0.13) * rr * 0.9, d * len, Color("fff4e0") if sp else col.darkened(0.2))
			ci.draw_circle(Vector2.ZERO, rr, col)
			ci.draw_circle(Vector2(0, rr * 0.2), rr * 0.6, col.lightened(0.3))
			ci.draw_set_transform(pos, 0.0, Vector2.ONE)
			eye(ci, Vector2(-rr * 0.32, -rr * 0.2), rr * 0.25, to_player, eyes)
			eye(ci, Vector2(rr * 0.32, -rr * 0.2), rr * 0.25, to_player, eyes, -1.0)
		"boss":
			var face := to_player.angle()
			ci.draw_set_transform(pos, face, Vector2.ONE)
			# fins
			for side in [-1.0, 1.0]:
				tri(ci, Vector2(-r * 0.3, side * r * 0.8), Vector2(-r * 1.1, side * r * 1.25), Vector2(-r * 0.9, side * r * 0.4), col.lightened(0.15))
			tri(ci, Vector2(-r * 0.85, 0), Vector2(-r * 1.6, -r * 0.6), Vector2(-r * 1.6, r * 0.6), col.lightened(0.1))
			ci.draw_circle(Vector2.ZERO, r, col)
			ci.draw_circle(Vector2(r * 0.15, 0), r * 0.7, col.lightened(0.12))
			# huge toothy mouth facing you
			var mo := 0.55 + 0.25 * sin(t * 2.0) + (0.3 if e.tell > 0.0 else 0.0)
			ellipse(ci, Vector2(r * 0.62, 0), r * 0.32, r * 0.5 * mo, MOUTH)
			for i in 7:
				var y := (i - 3) * r * 0.14 * mo
				tri(ci, Vector2(r * 0.42, y - r * 0.05), Vector2(r * 0.42, y + r * 0.05), Vector2(r * 0.58, y), Color.WHITE)
				tri(ci, Vector2(r * 0.9, y - r * 0.05), Vector2(r * 0.9, y + r * 0.05), Vector2(r * 0.76, y), Color.WHITE)
			eye(ci, Vector2(r * 0.15, -r * 0.5), r * 0.14, Vector2.RIGHT, "angry")
			eye(ci, Vector2(r * 0.15, r * 0.5), r * 0.14, Vector2.RIGHT, "angry", -1.0)
			# lantern on a stalk
			var lt := Vector2(r * 1.25, -r * 0.55 + sin(t * 2.5) * r * 0.05)
			ci.draw_polyline(PackedVector2Array([Vector2(r * 0.2, -r * 0.75), Vector2(r * 0.8, -r * 1.05), lt]), col.lightened(0.3), r * 0.05, true)
			ci.draw_circle(lt, r * 0.12, Color("ff5d73") if e.tell > 0.0 else LURE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if stunned:
		for i in 3:
			var a := t * 5.0 + TAU * i / 3.0
			ci.draw_circle(pos + Vector2(cos(a) * r * 0.7, -r * 1.1 + sin(a) * r * 0.2), maxf(2.0, r * 0.12), Color("fff27a"))
	# readability: too-big prey wear a red ring; hookable prey near you get a faint white one
	if not hooked:
		if not v.get("hookable", true):
			ci.draw_arc(pos, r * 1.25, 0, TAU, 32, Color(1, 0.3, 0.35, 0.65), maxf(2.0, r * 0.06), true)
		elif v.get("near", false):
			ci.draw_arc(pos, r * 1.2, 0, TAU, 32, Color(1, 1, 1, 0.25), maxf(1.5, r * 0.04), true)


static func glow_for_enemy(ci: CanvasItem, e, t: float, player: Vector2) -> void:
	match e.kind:
		"spitter":
			glow(ci, e.pos, e.radius * (2.6 if e.tell > 0.0 else 1.8), Color(0.78, 0.5, 1.0, 0.35 if e.tell <= 0.0 else 0.7))
		"boss":
			var face: float = (player - e.pos).angle()
			glow(ci, e.pos, e.radius * 2.0, Color(0.2, 0.5, 1.0, 0.22))
			var lt: Vector2 = e.pos + Vector2(e.radius * 1.25, -e.radius * 0.55).rotated(face)
			var lc := Color(1.0, 0.35, 0.4, 0.9) if e.tell > 0.0 else Color(1.0, 0.95, 0.5, 0.75)
			glow(ci, lt, e.radius * (0.9 + 0.1 * sin(t * 4.0)), lc)
		"puffer":
			if e.spiky:
				glow(ci, e.pos, e.radius * 1.9, Color(1.0, 0.6, 0.2, 0.25))
		_:
			glow(ci, e.pos, e.radius * 1.5, Color(KIND_COLORS[e.kind], 0.12))
