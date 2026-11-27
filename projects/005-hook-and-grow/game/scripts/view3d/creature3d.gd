class_name Creature3D
extends Node3D
## One low-poly creature for the 3D arena, built from primitives at unit radius (forward +X, up +Y)
## and scaled to the sim radius. The node sits on the seabed at the creature's XZ position; `rig`
## carries height, yaw, squash/stretch and scale; `shadow` is the soft blob on the floor.
## Morsel's trait body parts are prebuilt up to the trait cap and switched on as levels rise.

const MAX_TRAIT := 6

var kind := ""
var rig: Node3D
var shadow: MeshInstance3D
var marker: MeshInstance3D        # hookable / too-big ring on the floor
var body_mat: StandardMaterial3D
var base_col := Color.WHITE
var eyes: Array = []              # [{root, white, pupil, shine, brow, out}]
var p: Dictionary = {}            # named parts
var traits_parts: Dictionary = {} # trait -> Array of [level, node]
var stars: Node3D
var heading := 0.0
var radius := 1.0                 # world units
var height := 1.0


static func make(k: String) -> Creature3D:
	var c := Creature3D.new()
	c.kind = k
	c.name = k
	c._build()
	return c


func _build() -> void:
	shadow = Kit3D.part(self, Kit3D.floor_quad(), Kit3D.shadow_mat(), Vector3(0, 0.02, 0), Vector3.ONE)
	marker = Kit3D.part(self, Kit3D.ring(0.1), Kit3D.flat(Color(1, 0.3, 0.35, 0.7)), Vector3(0, 0.04, 0), Vector3.ONE)
	marker.visible = false
	rig = Node3D.new()
	add_child(rig)
	base_col = Look.PLAYER if kind == "morsel" else Look.KIND_COLORS[kind]
	body_mat = Kit3D.make_mat(base_col, 0.0, 0.5)
	match kind:
		"morsel": _build_morsel()
		"nibbler": _build_nibbler()
		"darter": _build_darter()
		"shellback": _build_shellback()
		"spitter": _build_spitter()
		"puffer": _build_puffer()
		"boss": _build_boss()
	if not p.has("pool"):  # every prey glows faintly on the seabed in its colour (a "pickup" read)
		p["pool"] = Kit3D.floor_glow(self, Color(base_col, 0.2), 3.0)
	stars = Node3D.new()
	rig.add_child(stars)
	for i in 3:
		Kit3D.part(stars, Kit3D.sphere(6, 3), Kit3D.mat(Color("fff27a"), 2.0), Vector3.ZERO, Vector3.ONE * 0.13)
	stars.visible = false


# =============================================================================
# eyes
# =============================================================================

func _eye(at: Vector3, r: float) -> void:
	var root := Node3D.new()
	root.position = at
	rig.add_child(root)
	var out := at.normalized()
	var white := Kit3D.part(root, Kit3D.sphere(10, 5), Kit3D.mat(Color.WHITE, 0.15, 0.3), Vector3.ZERO, Vector3.ONE * r)
	var pupil := Kit3D.part(root, Kit3D.sphere(8, 4), Kit3D.mat(Look.EYE_DARK, 0.0, 0.2), out * r * 0.62, Vector3.ONE * r * 0.55)
	var shine := Kit3D.part(root, Kit3D.sphere(6, 3), Kit3D.flat(Color.WHITE), out * r * 0.9 + Vector3(0, r * 0.3, 0), Vector3.ONE * r * 0.16)
	var brow := Kit3D.part(root, Kit3D.box(), Kit3D.mat(Look.EYE_DARK), Vector3(0, r * 1.05, 0), Vector3(r * 1.6, r * 0.32, r * 0.5))
	brow.visible = false
	eyes.append({"root": root, "white": white, "pupil": pupil, "shine": shine, "brow": brow, "out": out, "r": r,
		"side": signf(at.z)})


## mode: normal | happy | hurt | angry | wide | closed. look: creature-local direction.
func set_eyes(mode: String, look: Vector3) -> void:
	for e in eyes:
		var root: Node3D = e["root"]
		var r: float = e["r"]
		var out: Vector3 = e["out"]
		var squint := mode == "happy" or mode == "closed" or mode == "hurt"
		root.scale = Vector3(1.0, 0.18 if squint else 1.0, 1.0)
		if mode == "happy":
			root.scale = Vector3(1.0, 0.3, 1.0)
		var pupil: MeshInstance3D = e["pupil"]
		pupil.visible = not squint
		(e["shine"] as MeshInstance3D).visible = not squint
		var d := (out + look.normalized() * 0.8).normalized()
		pupil.position = d * r * 0.62
		pupil.scale = Vector3.ONE * r * (0.36 if mode == "wide" else 0.55)
		(e["shine"] as MeshInstance3D).position = d * r * 0.95 + Vector3(0, r * 0.25, 0)
		var brow: MeshInstance3D = e["brow"]
		brow.visible = mode == "angry"
		if brow.visible:
			brow.rotation = Vector3(0.45 * e["side"], 0, 0)


# =============================================================================
# models (unit radius, forward +X)
# =============================================================================

func _build_morsel() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(16, 8), body_mat, Vector3.ZERO, Vector3.ONE)
	Kit3D.part(rig, Kit3D.sphere(12, 6), Kit3D.mat(Look.PLAYER_BELLY.lerp(Look.PLAYER, 0.35), 0.1), Vector3(0.3, -0.28, 0), Vector3(0.72, 0.6, 0.78))
	Kit3D.part(rig, Kit3D.sphere(8, 4), Kit3D.flat(Color(1, 1, 1, 0.35)), Vector3(-0.2, 0.72, -0.35), Vector3(0.28, 0.14, 0.22))
	p["mouth"] = Kit3D.part(rig, Kit3D.sphere(10, 5), Kit3D.mat(Look.MOUTH), Vector3(0.86, -0.12, 0), Vector3(0.2, 0.1, 0.4))
	_eye(Vector3(0.48, 0.52, -0.4), 0.34)
	_eye(Vector3(0.48, 0.52, 0.4), 0.34)
	# lure: a stalk and a glowing bulb in front. It *is* the hook, so it hides while the hook is out.
	var lure := Node3D.new()
	rig.add_child(lure)
	p["lure"] = lure
	var a := Vector3(0.5, 0.82, 0)
	var b := Vector3(1.38, 1.28, 0)
	Kit3D.part(lure, Kit3D.cylinder(5), Kit3D.mat(Look.PLAYER_DARK), (a + b) * 0.5, Vector3(0.05, a.distance_to(b), 0.05), Kit3D.basis_y(b - a))
	p["bulb"] = Kit3D.part(lure, Kit3D.sphere(10, 5), Kit3D.mat(Look.LURE, 4.0, 0.2), b, Vector3.ONE * 0.18)
	p["bulb_halo"] = Kit3D.halo(lure, Color(1.0, 0.95, 0.5, 0.55), 0.9, b)
	p["pool"] = Kit3D.floor_glow(self, Color(0.3, 0.9, 0.85, 0.35), 3.0)
	# traits, prebuilt to the cap
	var cap := MAX_TRAIT
	var sp: Array = []
	var fin_mat := Kit3D.mat(Look.TRAIT_COLORS["speed"], 0.3)
	sp.append([1, Kit3D.spike(rig, fin_mat, Vector3(-0.8, 0, 0), Vector3(-1, 0.05, 0), 0.85, 0.55, 0.22)])
	for i in cap - 1:
		var side := 1.0 if i % 2 == 0 else -1.0
		var ang := (1.85 + 0.28 * int(i / 2.0)) * side
		var base := Vector3(cos(ang), 0.1, sin(ang)) * 0.82
		var dir := Vector3(cos(ang + 0.35 * side), 0.2, sin(ang + 0.35 * side))
		sp.append([i + 2, Kit3D.spike(rig, fin_mat, base, dir, 0.6, 0.26, 0.25)])
	traits_parts["speed"] = sp
	var pr: Array = []
	var spine_mat := Kit3D.mat(Look.TRAIT_COLORS["pierce"], 0.4)
	for lvl in range(1, cap + 1):
		for j in 2:
			var i := (lvl - 1) * 2 + j
			var ang := PI + (i - 5.5) * 0.24
			var d := Vector3(cos(ang), 0.75, sin(ang)).normalized()
			pr.append([lvl, Kit3D.spike(rig, spine_mat, d * 0.85, d, 0.55, 0.11)])
	traits_parts["pierce"] = pr
	var ar: Array = []
	var plate_mat := Kit3D.mat(Look.TRAIT_COLORS["armour"], 0.0, 0.3)
	for i in cap:
		var ang := PI + (i - 2.5) * 0.5
		var d := Vector3(cos(ang), 0.85, sin(ang)).normalized()
		ar.append([i + 1, Kit3D.part(rig, Kit3D.sphere(8, 4), plate_mat, d * 0.78, Vector3(0.48, 0.2, 0.48), Kit3D.basis_y(d))])
	ar.append([3, Kit3D.part(rig, Kit3D.ring(0.14), plate_mat, Vector3(0, 0.05, 0), Vector3(1.04, 2.0, 1.04))])
	traits_parts["armour"] = ar
	var hr: Array = []
	var horn_mat := Kit3D.mat(Color("fff4e0"), 0.15, 0.3)
	for i in cap:
		var side := 1.0 if i % 2 == 0 else -1.0
		var ang := (0.75 + 0.3 * int(i / 2.0)) * side
		var base := Vector3(cos(ang), 0.5, sin(ang)).normalized() * 0.88
		var dir := Vector3(cos(ang * 0.8), 0.75, sin(ang * 0.8))
		hr.append([i + 1, Kit3D.spike(rig, horn_mat, base, dir, 0.6, 0.14)])
	traits_parts["damage"] = hr


func set_traits(levels: Dictionary) -> void:
	for t in traits_parts:
		var lvl := int(levels.get(t, 0))
		for pair in traits_parts[t]:
			(pair[1] as Node3D).visible = lvl >= int(pair[0])
	# horns grow a little with the level
	var dmg := int(levels.get("damage", 0))
	for pair in traits_parts.get("damage", []):
		var n: Node3D = pair[1]
		var s := 1.0 + 0.08 * dmg
		n.scale = Vector3(0.14, 0.6 * s, 0.14)


func _build_nibbler() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(12, 6), body_mat, Vector3.ZERO, Vector3.ONE)
	Kit3D.part(rig, Kit3D.sphere(10, 5), Kit3D.mat(base_col.lightened(0.3)), Vector3(0.2, -0.25, 0), Vector3(0.62, 0.55, 0.7))
	var tail := Node3D.new()
	tail.position = Vector3(-0.7, 0, 0)
	rig.add_child(tail)
	p["tail"] = tail
	Kit3D.spike(tail, Kit3D.mat(base_col.darkened(0.2)), Vector3.ZERO, Vector3(-1, 0.1, 0), 0.85, 0.6, 0.2)
	_eye(Vector3(0.42, 0.45, -0.36), 0.36)
	_eye(Vector3(0.42, 0.45, 0.36), 0.36)


func _build_darter() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(12, 6), body_mat, Vector3.ZERO, Vector3(1.35, 0.72, 0.78))
	Kit3D.spike(rig, Kit3D.mat(base_col.darkened(0.15)), Vector3(1.1, 0, 0), Vector3(1, 0, 0), 0.6, 0.32)
	var fin := Kit3D.mat(base_col.darkened(0.3))
	Kit3D.spike(rig, fin, Vector3(-1.0, 0, -0.1), Vector3(-1, 0.1, -0.7), 0.8, 0.35, 0.25)
	Kit3D.spike(rig, fin, Vector3(-1.0, 0, 0.1), Vector3(-1, 0.1, 0.7), 0.8, 0.35, 0.25)
	Kit3D.spike(rig, fin, Vector3(-0.1, 0.6, 0), Vector3(-0.6, 1, 0), 0.5, 0.3, 0.2)
	_eye(Vector3(0.6, 0.38, -0.36), 0.3)
	_eye(Vector3(0.6, 0.38, 0.36), 0.3)


func _build_shellback() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(12, 6), body_mat, Vector3.ZERO, Vector3(0.95, 0.8, 0.92))
	Kit3D.part(rig, Kit3D.sphere(8, 4), Kit3D.mat(base_col.lightened(0.15)), Vector3(-0.25, 0.5, 0), Vector3(0.5, 0.35, 0.5))
	p["mouth"] = Kit3D.part(rig, Kit3D.sphere(8, 4), Kit3D.mat(Look.MOUTH), Vector3(0.78, -0.05, 0), Vector3(0.18, 0.3, 0.35))
	_eye(Vector3(0.45, 0.5, -0.36), 0.24)
	_eye(Vector3(0.45, 0.5, 0.36), 0.24)
	# the front shell: a thick curved shield over the face (lifts up when it opens to bite)
	var shell := Node3D.new()
	rig.add_child(shell)
	p["shell"] = shell
	var smat := Kit3D.mat(Color("5c677d"), 0.0, 0.25)
	p["shell_mat"] = smat
	Kit3D.part(shell, Kit3D.sphere(12, 6), smat, Vector3(0.62, 0.05, 0), Vector3(0.5, 1.0, 1.2))
	for i in 3:
		Kit3D.part(shell, Kit3D.sphere(6, 3), Kit3D.mat(Color("8fa3c2"), 0.0, 0.3), Vector3(0.98, 0.1 + (i - 1) * 0.35, (i - 1) * 0.4), Vector3.ONE * 0.16)


func _build_spitter() -> void:
	var jelly := Kit3D.make_mat(Color(base_col, 0.82), 0.5, 0.2)
	body_mat = jelly
	p["body"] = Kit3D.part(rig, Kit3D.sphere(14, 7), jelly, Vector3(0, 0.1, 0), Vector3(1.0, 0.78, 1.0))
	Kit3D.part(rig, Kit3D.sphere(8, 4), Kit3D.mat(base_col.lightened(0.35), 1.0), Vector3(0, 0.25, 0), Vector3(0.5, 0.35, 0.5))
	var tent := Node3D.new()
	rig.add_child(tent)
	p["tentacles"] = tent
	var tmat := Kit3D.mat(base_col.darkened(0.15), 0.4)
	for i in 6:
		var a := TAU * i / 6.0
		var n := Node3D.new()
		n.position = Vector3(cos(a) * 0.55, -0.35, sin(a) * 0.55)
		tent.add_child(n)
		Kit3D.part(n, Kit3D.capsule(), tmat, Vector3(0, -0.5, 0), Vector3(0.18, 0.55, 0.18))
	_eye(Vector3(0.6, 0.3, -0.3), 0.24)
	_eye(Vector3(0.6, 0.3, 0.3), 0.24)
	p["pool"] = Kit3D.floor_glow(self, Color(0.78, 0.5, 1.0, 0.4), 3.0)


func _build_puffer() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(12, 6), body_mat, Vector3.ZERO, Vector3.ONE)
	Kit3D.part(rig, Kit3D.sphere(8, 4), Kit3D.mat(base_col.lightened(0.3)), Vector3(0.2, -0.3, 0), Vector3(0.65, 0.5, 0.7))
	var spikes := Node3D.new()
	rig.add_child(spikes)
	p["spikes"] = spikes
	p["spike_calm"] = Kit3D.mat(base_col.darkened(0.2))
	p["spike_hot"] = Kit3D.mat(Color("fff4e0"), 0.6)
	var list: Array = []
	var n := 16
	for i in n:  # golden-spiral directions over the upper 85% of the sphere
		var yy := 1.0 - 1.7 * (i + 0.5) / n
		var rr := sqrt(maxf(0.0, 1.0 - yy * yy))
		var a := i * 2.39996
		var d := Vector3(cos(a) * rr, yy, sin(a) * rr)
		list.append(Kit3D.spike(spikes, p["spike_calm"], d * 0.85, d, 0.4, 0.13))
	p["spike_list"] = list
	_eye(Vector3(0.62, 0.35, -0.32), 0.26)
	_eye(Vector3(0.62, 0.35, 0.32), 0.26)


func _build_boss() -> void:
	p["body"] = Kit3D.part(rig, Kit3D.sphere(16, 8), body_mat, Vector3.ZERO, Vector3(1.0, 0.82, 0.95))
	Kit3D.part(rig, Kit3D.sphere(12, 6), Kit3D.mat(base_col.lightened(0.15)), Vector3(0.2, -0.25, 0), Vector3(0.75, 0.55, 0.8))
	var fin := Kit3D.mat(base_col.lightened(0.15))
	Kit3D.spike(rig, fin, Vector3(-0.2, 0, -0.75), Vector3(-0.7, 0.1, -1), 0.8, 0.35, 0.2)
	Kit3D.spike(rig, fin, Vector3(-0.2, 0, 0.75), Vector3(-0.7, 0.1, 1), 0.8, 0.35, 0.2)
	Kit3D.spike(rig, fin, Vector3(-0.85, 0, 0), Vector3(-1, 0, 0), 0.8, 0.6, 0.2)
	Kit3D.spike(rig, fin, Vector3(-0.1, 0.75, 0), Vector3(-0.5, 1, 0), 0.5, 0.4, 0.15)
	var mouth := Node3D.new()
	mouth.position = Vector3(0.78, -0.12, 0)
	rig.add_child(mouth)
	p["mouth"] = mouth
	Kit3D.part(mouth, Kit3D.sphere(10, 5), Kit3D.mat(Look.MOUTH), Vector3.ZERO, Vector3(0.3, 0.5, 0.6))
	var tooth := Kit3D.mat(Color.WHITE, 0.2, 0.3)
	for i in 7:
		var z := (i - 3) * 0.15
		Kit3D.spike(mouth, tooth, Vector3(0.12, 0.35, z), Vector3(0.2, -1, 0), 0.22, 0.06)
		Kit3D.spike(mouth, tooth, Vector3(0.12, -0.35, z), Vector3(0.2, 1, 0), 0.22, 0.06)
	_eye(Vector3(0.45, 0.55, -0.48), 0.14)
	_eye(Vector3(0.45, 0.55, 0.48), 0.14)
	var a := Vector3(0.2, 0.78, 0)
	var b := Vector3(0.8, 1.15, 0)
	var c := Vector3(1.25, 0.95, 0)
	var stalk := Kit3D.mat(base_col.lightened(0.3))
	Kit3D.part(rig, Kit3D.cylinder(5), stalk, (a + b) * 0.5, Vector3(0.05, a.distance_to(b), 0.05), Kit3D.basis_y(b - a))
	Kit3D.part(rig, Kit3D.cylinder(5), stalk, (b + c) * 0.5, Vector3(0.04, b.distance_to(c), 0.04), Kit3D.basis_y(c - b))
	p["bulb_mat"] = Kit3D.make_mat(Look.LURE, 4.0, 0.2)
	p["bulb"] = Kit3D.part(rig, Kit3D.sphere(10, 5), p["bulb_mat"], c, Vector3.ONE * 0.13)
	p["bulb_pos"] = c
	p["halo"] = Kit3D.halo(rig, Color(1.0, 0.95, 0.5, 0.6), 1.0, c)
	p["pool"] = Kit3D.floor_glow(self, Color(0.2, 0.5, 1.0, 0.3), 3.0)


# =============================================================================
# per-frame pose
# =============================================================================

## Places the creature: XZ from the sim, rig height/yaw/scale/squash. sq = (forward, up, side).
func place(world_xz: Vector3, r: float, h: float, yaw_angle: float, sq: Vector3) -> void:
	radius = r
	height = h
	position = Vector3(world_xz.x, 0.0, world_xz.z)
	rig.position = Vector3(0, h, 0)
	rig.rotation = Vector3(0, ArenaSpace.yaw(yaw_angle), 0)
	rig.scale = Vector3(r * sq.x, r * sq.y, r * sq.z)
	# the shadow shrinks and fades as the body rises off the floor
	var lift := clampf((h - r) / maxf(r, 0.001), 0.0, 2.0)
	shadow.scale = Vector3.ONE * r * (1.25 - 0.15 * lift) * maxf(sq.x, sq.z)
	marker.scale = Vector3(r * 1.35, 1.0, r * 1.35)
	if p.has("pool"):
		(p["pool"] as Node3D).scale = Vector3.ONE * r * 3.0


func set_flash(white: float, red := 0.0) -> void:
	var c := base_col.lerp(Color.WHITE, white).lerp(Color("ff5d73"), red)
	c.a = body_mat.albedo_color.a
	body_mat.albedo_color = c
	body_mat.emission_enabled = white > 0.01 or kind == "spitter"
	if white > 0.01:
		body_mat.emission = Color.WHITE
		body_mat.emission_energy_multiplier = white * 1.5
	elif kind == "spitter":
		body_mat.emission = base_col
		body_mat.emission_energy_multiplier = 0.5


func set_stunned(on: bool, t: float) -> void:
	stars.visible = on
	if on:
		for i in 3:
			var a := t * 5.0 + TAU * i / 3.0
			(stars.get_child(i) as Node3D).position = Vector3(cos(a) * 0.7, 1.25, sin(a) * 0.7)


## World position of Morsel's lure bulb (also where the hook line starts).
func lure_world() -> Vector3:
	return rig.global_transform * Vector3(1.38, 1.28, 0)


func mouth_world() -> Vector3:
	return rig.global_transform * Vector3(0.9, 0.0, 0)
