class_name ArenaSpace
extends RefCounted
## Mapping between the sim's 2D play plane and the 3D view. The rules stay top-down: sim (x, y)
## maps to world (x, ?, y) * S, so "up" on the 2D screen (-y) is -Z (away from the camera).
## Mouse aim = camera ray through the cursor, intersected with the horizontal plane y = plane_y.

const S := 0.01   # world units per sim px (arena radius 2600 px -> 26 units)


static func to_world(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(p.x * S, y, p.y * S)


static func to_sim(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z) / S


## Where a ray hits the plane y = plane_y, or null if it is parallel to it or points away.
static func ray_to_plane(origin: Vector3, dir: Vector3, plane_y: float):
	if absf(dir.y) < 0.00001:
		return null
	var t := (plane_y - origin.y) / dir.y
	if t < 0.0:
		return null
	return origin + dir * t


## Screen position -> sim position on the play plane (null if the ray misses it).
static func screen_to_sim(camera: Camera3D, screen: Vector2, plane_y: float):
	var hit = ray_to_plane(camera.project_ray_origin(screen), camera.project_ray_normal(screen), plane_y)
	if hit == null:
		return null
	return to_sim(hit)


## Model yaw so that a model facing +X looks along the sim angle `a` (radians, sim plane).
static func yaw(a: float) -> float:
	return -a
