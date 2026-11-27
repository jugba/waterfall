class_name Seabed3D
extends Node3D
## The underwater set for the 3D arena, all from primitives and small shaders: a gradient seabed
## with animated caustics, the glowing arena rim, low-poly rocks, swaying kelp and glowing anemones
## (MultiMeshes, so a few draw calls), god-ray shafts and drifting marine snow that follow the camera.
## Lights and the Environment (fog, glow, ambient) are set up by `make_environment()`.

const SEABED_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform float arena_r = 26.0;
uniform vec3 center_col : source_color = vec3(0.16, 0.33, 0.38);
uniform vec3 mid_col : source_color = vec3(0.07, 0.17, 0.28);
uniform vec3 edge_col : source_color = vec3(0.02, 0.05, 0.10);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float caustic(vec2 p, float t) {
	float c = sin(p.x * 1.7 + t) + sin(p.y * 1.9 - t * 1.1) + sin((p.x + p.y) * 1.3 + t * 0.8)
		+ sin(length(p * 1.1) * 2.0 - t);
	return pow(1.0 - abs(sin(c * 1.2)), 6.0);
}
void fragment() {
	float d = length(wpos.xz) / arena_r;
	vec3 col = mix(center_col, mid_col, smoothstep(0.0, 0.75, d));
	col = mix(col, edge_col, smoothstep(0.9, 1.3, d));
	col *= 1.0 + 0.08 * sin(wpos.x * 2.3 + sin(wpos.z * 0.6) * 2.5);   // sand ripples
	float patch = sin(wpos.x * 0.37 + 1.3) * sin(wpos.z * 0.29 - 0.7) + 0.5 * sin((wpos.x - wpos.z) * 0.71);
	col = mix(col, col * vec3(1.45, 1.35, 1.1), smoothstep(0.35, 0.9, patch) * 0.6);   // pale sand patches
	col = mix(col, col * 0.6, smoothstep(0.4, 1.0, -patch) * 0.5);                      // dark silt
	ALBEDO = col;
	ROUGHNESS = 0.95;
	float c = caustic(wpos.xz * 1.6, TIME * 0.9) * 0.6 + caustic(wpos.xz * 0.45, TIME * 0.5) * 0.4;
	EMISSION = vec3(0.3, 0.65, 0.7) * c * 0.45 * (1.0 - smoothstep(0.85, 1.15, d));
}
"""

const KELP_SHADER := """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying float hh;
varying vec3 tint;
void vertex() {
	hh = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	vec3 ip = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float ph = ip.x * 0.7 + ip.z * 1.3;
	VERTEX.x += sin(TIME * 1.2 + ph) * 0.9 * hh * hh;
	VERTEX.z += cos(TIME * 0.9 + ph * 1.3) * 0.6 * hh * hh;
	tint = COLOR.rgb;
}
void fragment() {
	ALBEDO = tint * (0.45 + 0.75 * hh);
	EMISSION = tint * 0.25 * hh * hh;
	ROUGHNESS = 0.8;
}
"""

const GLOWDOT_SHADER := """
shader_type spatial;
render_mode unshaded;
varying vec3 tint;
varying float ph;
void vertex() {
	tint = COLOR.rgb;
	vec3 ip = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	ph = ip.x * 3.1 + ip.z * 1.7;
}
void fragment() {
	ALBEDO = tint * (1.3 + 0.6 * sin(TIME * 2.0 + ph));
}
"""

const RAY_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(0.55, 0.85, 1.0, 0.10);
uniform float seed = 0.0;
void fragment() {
	float edge = sin(UV.x * 3.14159);
	edge = edge * edge;
	float fade = smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.55, UV.y);
	float flick = 0.65 + 0.35 * sin(TIME * 0.6 + seed * 3.1);
	ALBEDO = tint.rgb;
	ALPHA = tint.a * edge * fade * flick;
}
"""

var arena_r := 26.0
var _rays: Array = []
var _snow: CPUParticles3D
var _rng := RandomNumberGenerator.new()


func build(arena_radius_world: float) -> void:
	arena_r = arena_radius_world
	_rng.seed = 5
	# seabed
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2.ONE * arena_r * 4.0
	var sh := Shader.new()
	sh.code = SEABED_SHADER
	var fm := ShaderMaterial.new()
	fm.shader = sh
	fm.set_shader_parameter("arena_r", arena_r)
	var floor_node := MeshInstance3D.new()
	floor_node.name = "Seabed"
	floor_node.mesh = floor_mesh
	floor_node.material_override = fm
	add_child(floor_node)
	# glowing arena rim
	var rim := Kit3D.part(self, Kit3D.ring(0.008), Kit3D.mat(Color(0.4, 0.8, 1.0), 2.5), Vector3(0, 0.05, 0),
		Vector3.ONE * arena_r)
	rim.name = "Rim"
	_build_rocks()
	_build_kelp()
	_build_glow_dots()
	_build_rays()
	_build_snow()


func _multimesh(mesh: Mesh, count: int, material: Material, node_name: String) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm


## Rocks: scattered boulders inside, a ring of big ones outside the rim as the arena wall.
func _build_rocks() -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 4
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	var inner := 110
	var outer := 70
	var mm := _multimesh(mesh, inner + outer, m, "Rocks")
	for i in inner + outer:
		var p: Vector2
		var s: float
		if i < inner:
			p = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * arena_r * 0.97
			s = _rng.randf_range(0.08, 0.45) * (1.0 + p.length() / arena_r * 2.2)
		else:
			p = Vector2.from_angle(TAU * (i - inner) / outer + _rng.randf() * 0.05) * arena_r * _rng.randf_range(1.06, 1.2)
			s = _rng.randf_range(1.2, 2.8)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s * _rng.randf_range(0.8, 1.4), s * _rng.randf_range(0.45, 0.9), s * _rng.randf_range(0.8, 1.3)))
		mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, -s * 0.15, p.y)))
		var g := _rng.randf_range(0.0, 1.0)
		mm.set_instance_color(i, Color(0.16, 0.2, 0.27).lerp(Color(0.24, 0.27, 0.3), g))


## Kelp: thin swaying cylinders; short tufts in the middle, tall forests near the rim (they never
## hide the fight at a 55 degree view).
func _build_kelp() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.35
	mesh.height = 1.0
	mesh.radial_segments = 5
	mesh.rings = 5
	var sh := Shader.new()
	sh.code = KELP_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var n := 240
	var mm := _multimesh(mesh, n, m, "Kelp")
	for i in n:
		var d := sqrt(_rng.randf())
		if i % 3 == 0:
			d = _rng.randf_range(0.85, 1.05)
		var p := Vector2.from_angle(_rng.randf() * TAU) * d * arena_r
		var h := _rng.randf_range(0.25, 0.7) * (1.0 + 4.0 * pow(d, 3.0))
		var w := maxf(0.06, h * _rng.randf_range(0.18, 0.26))
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(w, h, w))
		mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, h * 0.5, p.y)))
		var greens := [Color(0.18, 0.55, 0.42), Color(0.25, 0.6, 0.3), Color(0.15, 0.45, 0.5)]
		mm.set_instance_color(i, greens[i % 3])


func _build_glow_dots() -> void:
	var sh := Shader.new()
	sh.code = GLOWDOT_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var n := 90
	var mm := _multimesh(Kit3D.sphere(6, 3), n, m, "Anemones")
	for i in n:
		var p := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * arena_r
		var s := _rng.randf_range(0.03, 0.08) * (1.0 + p.length() / arena_r)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(p.x, s * 0.5, p.y)))
		mm.set_instance_color(i, [Color(0.4, 0.85, 1.0), Color(0.9, 0.5, 1.0), Color(0.5, 1.0, 0.7)][i % 3])


func _build_rays() -> void:
	var sh := Shader.new()
	sh.code = RAY_SHADER
	for i in 7:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("seed", float(i))
		m.set_shader_parameter("tint", Color(0.55, 0.85, 1.0, _rng.randf_range(0.14, 0.26)))
		var q := QuadMesh.new()
		q.size = Vector2(1, 1)
		var mi := MeshInstance3D.new()
		mi.name = "GodRay%d" % i
		mi.mesh = q
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_rays.append({"node": mi, "off": Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.4, 0.6)),
			"w": _rng.randf_range(0.25, 0.6), "ph": _rng.randf() * TAU})


func _build_snow() -> void:
	_snow = CPUParticles3D.new()
	_snow.name = "MarineSnow"
	_snow.amount = 160
	_snow.lifetime = 9.0
	_snow.preprocess = 9.0
	_snow.local_coords = false
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = Vector3(10, 3, 8)
	_snow.direction = Vector3(0.3, -1, 0)
	_snow.spread = 40.0
	_snow.gravity = Vector3(0, -0.05, 0)
	_snow.initial_velocity_min = 0.05
	_snow.initial_velocity_max = 0.2
	_snow.scale_amount_min = 0.5
	_snow.scale_amount_max = 1.5
	var q := QuadMesh.new()
	q.size = Vector2(0.04, 0.04)
	_snow.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_texture = Look.glow_texture()
	m.albedo_color = Color(0.7, 0.9, 1.0, 0.5)
	m.disable_fog = true
	_snow.material_override = m
	add_child(_snow)


## Keep the rays and snow around what the camera looks at, sized to the current camera distance.
func follow(target: Vector3, cam_dist: float, t: float) -> void:
	var k := cam_dist / 5.0
	for r in _rays:
		var mi: MeshInstance3D = r["node"]
		var off: Vector2 = r["off"]
		var sway := sin(t * 0.25 + float(r["ph"])) * 0.15
		mi.position = target + Vector3((off.x + sway) * 2.2 * k, 1.4 * k, off.y * 2.0 * k)
		mi.rotation = Vector3(-0.55, 0, 0.3 + sway * 0.3)   # leaning toward the camera so the shaft reads
		mi.scale = Vector3(float(r["w"]) * 1.6 * k, 4.5 * k, 1.0)
	_snow.position = target + Vector3(0, 1.0 * k, 0)
	_snow.emission_box_extents = Vector3(5.0 * k, 1.6 * k, 4.0 * k)
	var qm: QuadMesh = _snow.mesh
	if absf(qm.size.x - 0.04 * k) > 0.004 * k:
		qm.size = Vector2.ONE * 0.04 * k


static func make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.07, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.5, 0.65)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.15, 0.24)
	env.fog_density = 0.06
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.1
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	return env
