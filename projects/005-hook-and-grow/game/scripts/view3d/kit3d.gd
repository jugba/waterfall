class_name Kit3D
extends RefCounted
## Shared low-poly building blocks for the 3D arena: cached primitive meshes (unit size, scaled by
## the node), cached materials, additive glow halos, and helpers to place parts. Everything is
## built from primitives in code: no model or texture files. Compatibility-renderer safe.

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


# --- meshes (unit size: sphere radius 1, cone/cylinder height 1 along +Y, radius 1) ----------------

static func sphere(seg := 12, rings := 6) -> SphereMesh:
	var key := "sphere%d_%d" % [seg, rings]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = seg
		m.rings = rings
		_meshes[key] = m
	return _meshes[key]


static func hemisphere(seg := 12, rings := 4) -> SphereMesh:
	var key := "hemi%d_%d" % [seg, rings]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 1.0
		m.is_hemisphere = true
		m.radial_segments = seg
		m.rings = rings
		_meshes[key] = m
	return _meshes[key]


static func cone(seg := 6) -> CylinderMesh:
	var key := "cone%d" % seg
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = 0.0
		m.bottom_radius = 1.0
		m.height = 1.0
		m.radial_segments = seg
		m.rings = 0
		m.cap_top = false
		_meshes[key] = m
	return _meshes[key]


static func cylinder(seg := 6) -> CylinderMesh:
	var key := "cyl%d" % seg
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = 1.0
		m.bottom_radius = 1.0
		m.height = 1.0
		m.radial_segments = seg
		m.rings = 0
		_meshes[key] = m
	return _meshes[key]


static func capsule() -> CapsuleMesh:
	if not _meshes.has("capsule"):
		var m := CapsuleMesh.new()
		m.radius = 0.5
		m.height = 2.0
		m.radial_segments = 10
		m.rings = 3
		_meshes["capsule"] = m
	return _meshes["capsule"]


static func box() -> BoxMesh:
	if not _meshes.has("box"):
		var m := BoxMesh.new()
		m.size = Vector3.ONE
		_meshes["box"] = m
	return _meshes["box"]


## Flat ring in the XZ plane, outer radius 1.
static func ring(thickness := 0.08) -> TorusMesh:
	var key := "ring%.3f" % thickness
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = 1.0 - thickness
		m.outer_radius = 1.0
		m.rings = 40
		m.ring_segments = 4
		_meshes[key] = m
	return _meshes[key]


static func quad() -> QuadMesh:
	if not _meshes.has("quad"):
		var m := QuadMesh.new()
		m.size = Vector2(2, 2)
		_meshes["quad"] = m
	return _meshes["quad"]


## Horizontal quad (faces +Y), 2x2.
static func floor_quad() -> PlaneMesh:
	if not _meshes.has("floor_quad"):
		var m := PlaneMesh.new()
		m.size = Vector2(2, 2)
		_meshes["floor_quad"] = m
	return _meshes["floor_quad"]


# --- materials -------------------------------------------------------------------------------------

## Lit, slightly glossy toy material. emission > 0 makes it glow (picked up by the glow pass).
static func mat(col: Color, emission := 0.0, rough := 0.55) -> StandardMaterial3D:
	var key := "m%s_%.2f_%.2f" % [col.to_html(), emission, rough]
	if not _mats.has(key):
		_mats[key] = make_mat(col, emission, rough)
	return _mats[key]


static func make_mat(col: Color, emission := 0.0, rough := 0.55) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic_specular = 0.6
	m.rim_enabled = true      # soft underwater rim light makes the toy shapes read against the fog
	m.rim = 0.35
	m.rim_tint = 0.6
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emission
	return m


## Unshaded colour (eyes, line, UI-ish markers). add = additive blending.
static func flat(col: Color, add := false, no_depth := false) -> StandardMaterial3D:
	var key := "f%s_%s_%s" % [col.to_html(), add, no_depth]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		if col.a < 1.0 or add:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if add:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		if no_depth:
			m.no_depth_test = true
		m.disable_fog = add
		_mats[key] = m
	return _mats[key]


## Soft radial glow sprite, additive, always facing the camera.
static func halo_mat() -> StandardMaterial3D:
	if not _mats.has("halo"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true   # without this a billboard ignores node scale
		m.albedo_texture = Look.glow_texture()
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.disable_fog = true
		_mats["halo"] = m
	return _mats["halo"]


## Additive pool of light on the seabed (horizontal, so it is never clipped by the floor the way
## a billboard halo near the ground is). Own material copy per node so its colour can animate.
static func floor_glow(parent: Node3D, col: Color, size: float) -> MeshInstance3D:
	if not _mats.has("floor_glow"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = Look.glow_texture()
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.disable_fog = true
		_mats["floor_glow"] = m
	var mi := part(parent, floor_quad(), (_mats["floor_glow"] as Material).duplicate(), Vector3(0, 0.025, 0), Vector3.ONE * size)
	(mi.material_override as StandardMaterial3D).albedo_color = col
	return mi


## Dark soft blob on the seabed under each creature: the clearest size cue at an angle.
static func shadow_mat() -> StandardMaterial3D:
	if not _mats.has("shadow"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = Look.glow_texture()
		m.albedo_color = Color(0.0, 0.02, 0.05, 0.55)
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_mats["shadow"] = m
	return _mats["shadow"]


# --- placing parts -------------------------------------------------------------------------------

static func part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, scl: Vector3,
		basis := Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = Transform3D(basis.scaled_local(scl), pos)
	parent.add_child(mi)
	return mi


## A cone/cylinder part from `base` pointing along `dir` with length `len` and base radius `r`.
## `flat` < 1 flattens it sideways (fins).
static func spike(parent: Node3D, material: Material, base: Vector3, dir: Vector3, length: float, r: float,
		flatten := 1.0, seg := 6) -> MeshInstance3D:
	var b := basis_y(dir)
	return part(parent, cone(seg), material, base + b.y * length * 0.5, Vector3(r, length, r * flatten), b)


## Basis whose +Y axis points along `dir` (right-handed).
static func basis_y(dir: Vector3, hint := Vector3.UP) -> Basis:
	var y := dir.normalized()
	var ref := hint if absf(y.dot(hint)) < 0.98 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


static func halo(parent: Node3D, col: Color, size: float, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = quad()
	mi.material_override = halo_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3.ONE * size
	parent.add_child(mi)
	set_halo(mi, col)
	return mi


## Each halo keeps its own small material copy so its colour/brightness can animate.
static func set_halo(mi: MeshInstance3D, col: Color) -> void:
	var m: StandardMaterial3D = mi.material_override
	if m == _mats.get("halo"):
		m = m.duplicate()
		mi.material_override = m
	m.albedo_color = col
