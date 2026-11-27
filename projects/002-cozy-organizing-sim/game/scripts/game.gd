extends Node2D
## Knolling Co. greybox job: intro -> tip (items scatter) -> sort (drag, snap, rotate) ->
## photo (neatness score reveal) -> pack back (drag every item into the container's grid,
## it zips shut when full; "pack the rest" or Settings "Skip packing" do it automatically) -> payday.
##
## Mouse: drag items, right-click / wheel rotates. Controller: stick moves a cursor, A grabs /
## drops, d-pad jumps between items (or nudges the held item one cell), LB/RB rotate, Y photo.
## Keyboard: WASD/arrows like the d-pad, Space grab/drop, Q/E/R rotate, Enter/F photo.
## Progress (best scores, completed jobs, money) is kept in SaveGame slot 0 via Progress.

signal phase_changed(new_phase: int)

enum Phase { INTRO, TIPPING, SORTING, REVEAL, PACKING, DONE }

const SAVE_SLOT := 0
const TITLE_SCENE := "res://scenes/title.tscn"
const JOBS_SCENE := "res://scenes/job_select.tscn"
const CURSOR_SPEED := 900.0
const STICK_DEADZONE := 0.22
const PARK_POS := Vector2(1168, 660)
const PARK_SCALE := 0.42
const TIP_POS := Vector2(544, 420)
const PHOTO_ZOOM := 0.76
const PHOTO_CAM := Vector2(848, 440)
const PACK_GAP := 3   ## cells between the desk mat and the open container in the pack phase
const HINT_MOUSE := "Drag: sort     Right-click / wheel: turn     Enter: photo"
const HINT_PAD := "Stick: move   A: grab   D-pad: jump   LB/RB: turn   Y: photo"
const HINT_PACK_MOUSE := "Drag it all in     Right-click: turn     Enter: pack the rest"
const HINT_PACK_PAD := "Stick: move   A: grab   D-pad: jump   LB/RB: turn   Y: pack rest"
const HINTS := [HINT_MOUSE, HINT_PAD, HINT_PACK_MOUSE, HINT_PACK_PAD]

## -1 = randomise the tip each time; tests and the capture set a fixed seed.
@export var rng_seed := -1
## -1 = continue from the save. Set before adding to the tree to force a job.
@export var start_job_index := -1

var phase := Phase.INTRO
var job_index := 0
var job: Dictionary = {}
var items: Array[DeskItem] = []
var last_result: Dictionary = {}
var last_pay := 0
var progress: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _held: DeskItem
var _hovered: DeskItem
var _grab_offset := Vector2.ZERO
var _cursor := Vector2(544, 440)
var _pad_mode := false
var _shake := 0.0
var _pour: Array[DeskItem] = []
var _pour_timer := 0.0
var _tip_time := 0.0
var _puffs: Array[CPUParticles2D] = []
var _next_puff := 0
var _autoplay := false
var _pack_time := 0.0
var _pack_seconds := -1.0
var _pack_auto := false
var _closing := false   ## pack phase: auto-packing or zipping shut; input is ignored

@onready var desk: Desk = $Desk
@onready var items_root: Node2D = $Items
@onready var container_box: ContainerBox = $Container
@onready var camera: Camera2D = $Camera
@onready var cursor_node: Node2D = $Cursor
@onready var hud: Hud = $HUD


func _ready() -> void:
	_autoplay = OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay")
	if _autoplay:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--job="):
				start_job_index = int(arg.trim_prefix("--job=")) - 1
			elif arg.begins_with("--seed="):
				rng_seed = int(arg.trim_prefix("--seed="))
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	for i in 6:
		var p := _make_puff()
		add_child(p)
		_puffs.append(p)
	hud.start_pressed.connect(begin_tip)
	hud.photo_pressed.connect(take_photo)
	hud.pack_pressed.connect(func(): start_packing(Settings.auto_pack))
	hud.pack_rest_pressed.connect(func(): pack_rest())
	hud.next_pressed.connect(func(): start_job(job_index + 1))
	hud.retry_pressed.connect(func(): start_job(job_index))
	hud.title_pressed.connect(func(): SceneChanger.change_to(JOBS_SCENE))
	cursor_node.draw.connect(_draw_cursor)
	progress = Progress.load_progress()
	var first := start_job_index
	if first < 0 and Progress.pending_job >= 0:
		first = Progress.pending_job
	Progress.pending_job = -1
	if first < 0:
		first = Progress.suggested_job(progress)
	start_job(first)
	Sfx.play_music("desk")
	if _autoplay:
		_run_autoplay()


# --- job flow -----------------------------------------------------------------

func start_job(index: int) -> void:
	job_index = posmod(index, maxi(1, Catalog.job_count()))
	job = Catalog.job(job_index)
	for it in items:
		it.queue_free()
	items.clear()
	_held = null
	_hovered = null
	_pour.clear()
	_closing = false
	_pack_seconds = -1.0
	hud.hide_item_tip()
	last_result = {}
	camera.zoom = Vector2.ONE
	camera.position = Vector2(640, 400)
	desk.hide_ghost()
	for d in Catalog.job_items(job):
		var it := DeskItem.new()
		it.setup(d)
		it.visible = false
		it.position = TIP_POS
		items_root.add_child(it)
		items.append(it)
	container_box.setup(job.get("container", {}))
	container_box.position = TIP_POS
	container_box.rotation = 0.0
	container_box.lid = 0.0
	container_box.scale = Vector2(0.2, 0.2)
	container_box.modulate.a = 0.0
	var t := container_box.create_tween().set_parallel()
	t.tween_property(container_box, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(container_box, "modulate:a", 1.0, 0.2)
	hud.set_job_title("Job %d/%d  -  %s  -  %d items" % [job_index + 1, Catalog.job_count(), job.get("title", ""), items.size()])
	hud.set_hint("")
	hud.show_intro(job, items.size())
	_set_phase(Phase.INTRO)


## The hook moment: the container wobbles, tips, and everything tumbles onto the desk.
func begin_tip() -> void:
	if phase != Phase.INTRO:
		return
	hud.hide_intro()
	_set_phase(Phase.TIPPING)
	_tip_time = 0.0
	var t := container_box.create_tween()
	t.tween_property(container_box, "rotation", -0.12, 0.12)
	t.tween_property(container_box, "rotation", 0.1, 0.1)
	t.tween_property(container_box, "lid", 1.0, 0.12)
	t.parallel().tween_property(container_box, "scale", Vector2(1.12, 1.12), 0.12)
	t.tween_property(container_box, "rotation", 0.5, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_start_pour)


func _start_pour() -> void:
	_pour = items.duplicate()
	_shuffle(_pour)
	_pour_timer = 0.0
	_shake = 16.0
	desk.flash = 0.25
	desk.create_tween().tween_property(desk, "flash", 0.0, 0.3)
	Audio.play_sfx(Sfx.get_stream("thunk"), 0.0, 0.03)
	Audio.play_sfx(Sfx.get_stream("tumble"), -2.0, 0.05)


func _spawn_from_container(it: DeskItem) -> void:
	it.visible = true
	it.position = TIP_POS + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-20, 20))
	it.rotation = _rng.randf_range(-PI, PI)
	var dir := Vector2.from_angle(_rng.randf_range(-PI, PI))
	it.velocity = dir * _rng.randf_range(420.0, 1150.0)
	it.spin = _rng.randf_range(-13.0, 13.0)
	it.lift = 1.0
	it.scale = Vector2(0.6, 0.6)
	var t := it.motion().set_parallel()
	t.tween_property(it, "lift", 0.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(it, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx(Sfx.get_stream("click"), -14.0, 0.25, 0.7)


func _end_tip(instant := false) -> void:
	if phase != Phase.TIPPING:
		return
	_set_phase(Phase.SORTING)
	if instant:
		container_box.position = PARK_POS
		container_box.scale = Vector2.ONE * PARK_SCALE
		container_box.rotation = 0.0
	else:
		var t := container_box.create_tween().set_parallel()
		t.tween_property(container_box, "position", PARK_POS, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(container_box, "scale", Vector2.ONE * PARK_SCALE, 0.45)
		t.tween_property(container_box, "rotation", 0.0, 0.45)
	hud.show_sorting()
	_refresh_hint()
	_update_live_score()


## Finish the tip at once (tests, capture): pour everything and run the physics until it rests.
func settle_now() -> void:
	if phase == Phase.INTRO:
		begin_tip()
	if phase != Phase.TIPPING:
		return
	if _pour.is_empty() and not items.is_empty() and not items[0].visible:
		_start_pour()
	while not _pour.is_empty():
		_spawn_from_container(_pour.pop_front())
	for i in 400:
		_step_loose(1.0 / 60.0)
		if _all_resting():
			break
	_end_tip(true)


func take_photo() -> Dictionary:
	if phase != Phase.SORTING:
		return {}
	if _held:
		drop_held(true)
	_set_hover(null)
	desk.hide_ghost()
	last_result = Neatness.evaluate(_entries())
	last_pay = roundi(int(job.get("pay", 0)) * (0.5 + float(last_result["total"]) / 100.0))
	_record_result()
	_set_phase(Phase.REVEAL)
	hud.set_hint("")
	hud.flash()
	Audio.play_sfx(Sfx.get_stream("shutter"), 0.0, 0.0)
	# Frame the flat-lay like a photo: zoom out and slide the desk left of the score card.
	var t := camera.create_tween().set_parallel()
	t.tween_property(camera, "zoom", Vector2.ONE * PHOTO_ZOOM, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", PHOTO_CAM, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hud.reveal(last_result, last_pay)
	return last_result


## Pack-back phase: the container opens next to the desk showing its grid; the player drags
## every item in (same grab / turn / snap as sorting). When the last one fits it zips shut.
## `auto` packs everything by itself (Settings "Skip packing"); `instant` finishes at once (tests).
func start_packing(auto := false, instant := false) -> void:
	if phase != Phase.REVEAL:
		return
	_set_phase(Phase.PACKING)
	_closing = false
	_pack_time = 0.0
	_pack_auto = auto
	_set_hover(null)
	for it in items:
		it.packed = false
		if not it.placed:
			place(it, it.snapped_angle(), true)
	container_box.interior = true
	container_box.zip = 0.0
	container_box.lid = 1.0
	var centre := pack_rect_px().get_center()
	var area := Desk.rect_px().merge(pack_rect_px()).grow(Desk.CELL)
	var zoom := minf(1240.0 / area.size.x, 580.0 / area.size.y)
	if instant:
		container_box.position = centre
		container_box.scale = Vector2.ONE
		container_box.rotation = 0.0
		camera.zoom = Vector2.ONE * zoom
		camera.position = area.get_center()
		pack_rest(true)
		return
	hud.show_packing(container_box.label)
	_refresh_hint()
	_update_pack_status()
	var cam := camera.create_tween().set_parallel()
	cam.tween_property(camera, "zoom", Vector2.ONE * zoom, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cam.tween_property(camera, "position", area.get_center(), 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	container_box.scale = Vector2.ONE * 0.6
	var box := container_box.create_tween().set_parallel()
	box.tween_property(container_box, "position", centre, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	box.tween_property(container_box, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	box.tween_property(container_box, "rotation", 0.0, 0.3)
	Audio.play_sfx(Sfx.get_stream("thunk"), -8.0, 0.03, 1.4)
	if auto:
		_closing = true
		await box.finished
		_closing = false
		pack_rest()


## Old name kept for tests / autoplay: packs automatically (instant = no animation).
func pack_back(instant := false) -> void:
	start_packing(true, instant)


## The container's interior grid, in desk-cell coordinates (it sits right of the mat, on the
## same 32 px lattice, so the desk's ghost / snap maths work unchanged).
func pack_rect() -> Rect2i:
	var c := container_box.cells
	return Rect2i(Vector2i(Desk.COLS + PACK_GAP, maxi(0, (Desk.ROWS - c.y) / 2)), c)


func pack_rect_px() -> Rect2:
	var r := pack_rect()
	return Rect2(Desk.cell_to_px(Vector2(r.position)), Vector2(r.size) * Desk.CELL)


func packed_count() -> int:
	var n := 0
	for it in items:
		n += 1 if it.packed else 0
	return n


func over_bag(world: Vector2) -> bool:
	return phase == Phase.PACKING and pack_rect_px().grow(Desk.CELL).has_point(world)


## Packs every item not yet in the container into the free space (or repacks everything if
## the player's layout leaves no room), then zips it shut.
func pack_rest(instant := false) -> void:
	if phase != Phase.PACKING or _closing:
		return
	if _held:
		drop_held(true)
	var rect := pack_rect()
	var movers: Array[DeskItem] = []
	var occupied: Array[Rect2i] = []
	for it in items:
		if it.packed:
			occupied.append(Rect2i(it.cell - rect.position, it.grid_size()))
		else:
			movers.append(it)
	var fit := Layouts.pack_into(_sizes_of(movers), rect.size.x, rect.size.y, occupied)
	if fit.is_empty() and not movers.is_empty():
		movers = items.duplicate()
		fit = Layouts.pack_into(_sizes_of(movers), rect.size.x, rect.size.y)
	if fit.size() != movers.size():
		_close_bag(instant)  # data error (container too small): never block the player
		return
	_closing = true
	_set_hover(null)
	var last: Tween
	for k in movers.size():
		var it: DeskItem = movers[k]
		var r: Rect2i = fit[k]
		var angle := 0.0 if r.size == it.base_size else PI / 2.0
		it.cell = rect.position + r.position
		it.placed = true
		it.packed = true
		var target := Desk.centre_of(it.cell, r.size)
		if instant:
			it.stop_motion()
			it.position = target
			it.rotation = angle
			it.lift = 0.0
			continue
		var t := it.motion()
		t.tween_interval(k * 0.05)
		t.tween_property(it, "lift", 1.0, 0.06)
		t.tween_property(it, "position", target, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t.parallel().tween_property(it, "rotation", angle, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(it, "lift", 0.0, 0.06)
		t.tween_callback(func():
			Audio.play_sfx(Sfx.get_stream("pack_drop"), -4.0, 0.06, 0.9 + k * 0.02)
			_update_pack_status())
		last = t
	if instant or last == null:
		_close_bag(instant)
		return
	await last.finished
	_close_bag()


func _sizes_of(list: Array[DeskItem]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for it in list:
		out.append(it.base_size)
	return out


func _check_packed() -> void:
	if phase == Phase.PACKING and not _closing and packed_count() == items.size():
		_close_bag()


## The satisfying bit: the zip runs across, items vanish under the flap, the bag pops.
func _close_bag(instant := false) -> void:
	_closing = true
	_pack_seconds = -1.0 if _pack_auto else _pack_time
	desk.hide_ghost()
	_set_hover(null)
	hud.hide_item_tip()
	if instant:
		for it in items:
			it.visible = false
		container_box.zip = 1.0
		_finish_pack()
		return
	Audio.play_sfx(Sfx.get_stream("zip"), -2.0, 0.04)
	var t := container_box.create_tween()
	t.tween_property(container_box, "zip", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func():
		for it in items:
			it.visible = false
		_shake = 7.0
		Audio.play_sfx(Sfx.get_stream("thunk"), -2.0, 0.0, 1.3))
	t.tween_property(container_box, "scale", Vector2(1.07, 0.93), 0.06)
	t.tween_property(container_box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await t.finished
	_finish_pack()


func _finish_pack() -> void:
	if phase != Phase.PACKING:
		return
	var earned := int(progress.get("money", 0)) + last_pay
	progress["money"] = earned
	var newly := Progress.mark_completed(progress, job_index)
	Progress.save(progress)
	_set_phase(Phase.DONE)
	hud.set_hint("")
	var unlocked := ""
	if newly >= 0:
		unlocked = String(Catalog.job(newly).get("title", ""))
		Audio.play_sfx(Sfx.get_stream("unlock"), -4.0, 0.0)
	var cam := camera.create_tween().set_parallel()
	cam.tween_property(camera, "zoom", Vector2.ONE * PHOTO_ZOOM, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cam.tween_property(camera, "position", PHOTO_CAM, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hud.show_payday(last_pay, earned, job_index + 1 < Catalog.job_count(), _pack_seconds, unlocked)


func _update_pack_status() -> void:
	hud.set_pack_status(packed_count(), items.size(), _pack_time)


func _record_result() -> void:
	Progress.record_best(progress, job_index, int(last_result["total"]))
	Progress.save(progress)


func _interactive() -> bool:
	return phase == Phase.SORTING or (phase == Phase.PACKING and not _closing)


func _refresh_hint() -> void:
	if phase == Phase.SORTING:
		hud.set_hint(HINT_PAD if _pad_mode else HINT_MOUSE)
	elif phase == Phase.PACKING:
		hud.set_hint(HINT_PACK_PAD if _pad_mode else HINT_PACK_MOUSE)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


# --- sorting ------------------------------------------------------------------

func _entries() -> Array:
	var out := []
	for it in items:
		out.append(it.score_entry())
	return out


func loose_count() -> int:
	var n := 0
	for it in items:
		n += 0 if it.placed else 1
	return n


func _update_live_score() -> void:
	hud.set_live_score(Neatness.evaluate(_entries())["total"], loose_count())


## Topmost item under a world point.
func item_at(world: Vector2) -> DeskItem:
	for i in range(items_root.get_child_count() - 1, -1, -1):
		var it := items_root.get_child(i) as DeskItem
		if it and it.visible and it.contains_point(world):
			return it
	return null


func grab(it: DeskItem, world: Vector2) -> void:
	if it == null or not _interactive() or _held:
		return
	_held = it
	it.held = true
	it.placed = false
	it.packed = false
	it.velocity = Vector2.ZERO
	it.spin = 0.0
	_grab_offset = Vector2.ZERO if _pad_mode else (it.position - world)
	items_root.move_child(it, -1)
	_set_hover(null)
	var t := it.motion().set_parallel()
	t.tween_property(it, "lift", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(it, "rotation", it.snapped_angle(), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play_sfx(Sfx.get_stream("pick"), -4.0, 0.08)


func drop_held(instant := false) -> void:
	if _held == null:
		return
	var it := _held
	_held = null
	it.held = false
	desk.hide_ghost()
	place(it, it.snapped_angle(), instant)


## Snap an item onto the grid at `angle` (a multiple of 90 deg), at the free spot nearest to
## where it is now. Loose items under it are bumped away.
func place(it: DeskItem, angle: float, instant := false) -> void:
	var q := posmod(roundi(angle / (PI / 2.0)), 4)
	var size := it.grid_size(q)
	var land := landing(it, it.position, size)
	var cell: Vector2i = land[0]
	it.cell = cell
	it.placed = true
	it.packed = land[1]
	var target := Desk.centre_of(cell, size)
	var g := _guides(Rect2i(cell, size), it)
	var aligned: bool = not g[0].is_empty() or not g[1].is_empty()
	if instant:
		it.stop_motion()
		it.position = target
		it.rotation = angle
		it.lift = 0.0
		it.tilt = 0.0
		_after_snap(it, false, aligned)
		return
	var t := it.motion().set_parallel()
	t.tween_property(it, "position", target, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(it, "rotation", angle, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(it, "lift", 0.0, 0.11).set_ease(Tween.EASE_IN)
	t.tween_property(it, "tilt", 0.0, 0.11)
	t.chain().tween_callback(_after_snap.bind(it, true, aligned))


func _after_snap(it: DeskItem, juicy: bool, aligned: bool) -> void:
	_bump_loose_from(it)
	if juicy:
		var area := it.base_size.x * it.base_size.y
		if it.packed:
			Audio.play_sfx(Sfx.get_stream("pack_drop"), -2.0, 0.06, clampf(1.2 - area * 0.04, 0.75, 1.2))
		else:
			Audio.play_sfx(Sfx.get_stream("click"), 0.0, 0.04, clampf(1.3 - area * 0.05, 0.75, 1.3))
		if aligned:  # second, higher click when it lines up with a neighbour
			Audio.play_sfx(Sfx.get_stream("tick"), -5.0, 0.02, 1.25)
		var sq := it.create_tween()
		sq.tween_property(it, "squash", 0.93, 0.04)
		sq.tween_property(it, "squash", 1.0, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_puff(it)
		_shake = maxf(_shake, 1.5)
	if phase == Phase.SORTING:
		_update_live_score()
	elif phase == Phase.PACKING:
		_update_pack_status()
		_check_packed()


func rotate_item(it: DeskItem, dir: int) -> void:
	if it == null or not _interactive():
		return
	var angle := it.snapped_angle() + dir * PI / 2.0
	Audio.play_sfx(Sfx.get_stream("tick"), -3.0, 0.05, 0.9)
	if it.held:
		it.motion().tween_property(it, "rotation", angle, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		place(it, angle)


## Where a drop at `centre` lands: [top-left cell, in the container?]. In the pack phase a drop
## over the open container goes into its grid; if it doesn't fit there it goes back on the desk.
func landing(it: DeskItem, centre: Vector2, size: Vector2i) -> Array:
	if over_bag(centre):
		var c := resolve_cell(it, centre, size, true)
		if c.x >= 0:
			return [c, true]
	return [resolve_cell(it, centre, size, false), false]


## Nearest free top-left cell for an item of `size` near world position `centre`, on the desk
## or (in_bag) inside the container grid. In the container, (-1, -1) means it doesn't fit.
func resolve_cell(it: DeskItem, centre: Vector2, size: Vector2i, in_bag := false) -> Vector2i:
	var bounds := pack_rect() if in_bag else Rect2i(0, 0, Desk.COLS, Desk.ROWS)
	var none := Vector2i(-1, -1)
	if in_bag and (size.x > bounds.size.x or size.y > bounds.size.y):
		return none
	var want_f := Desk.px_to_cell(centre) - Vector2(size) * 0.5
	var want := Vector2i(roundi(want_f.x), roundi(want_f.y))
	want.x = clampi(want.x, bounds.position.x, bounds.end.x - size.x)
	want.y = clampi(want.y, bounds.position.y, bounds.end.y - size.y)
	var blocked: Array[Rect2i] = []
	for other in items:
		if other != it and other.placed and other.visible and other.packed == in_bag:
			blocked.append(Rect2i(other.cell, other.grid_size()))
	for r in maxi(bounds.size.x, bounds.size.y):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := want + Vector2i(dx, dy)
				var rect := Rect2i(c, size)
				if not bounds.encloses(rect) or _hits(rect, blocked):
					continue
				var d := (Vector2(c) - want_f).length_squared()
				if d < best_d:
					best_d = d
					best = c
		if best.x >= 0:
			return best
	return none if in_bag else want


func _hits(r: Rect2i, blocked: Array[Rect2i]) -> bool:
	for b in blocked:
		if r.intersects(b):
			return true
	return false


## Alignment guides for a candidate rect: [x lines, y lines] in cells where it shares an edge
## or centre with a placed item.
func _guides(r: Rect2i, ignore: DeskItem) -> Array:
	var gx: Array[float] = []
	var gy: Array[float] = []
	if phase != Phase.SORTING:
		return [gx, gy]
	var mine_x := [float(r.position.x), float(r.end.x), r.position.x + r.size.x * 0.5]
	var mine_y := [float(r.position.y), float(r.end.y), r.position.y + r.size.y * 0.5]
	for other in items:
		if other == ignore or not other.placed:
			continue
		var o := Rect2i(other.cell, other.grid_size())
		var ox := [float(o.position.x), float(o.end.x), o.position.x + o.size.x * 0.5]
		var oy := [float(o.position.y), float(o.end.y), o.position.y + o.size.y * 0.5]
		for v in mine_x:
			if ox.has(v) and not gx.has(v):
				gx.append(v)
		for v in mine_y:
			if oy.has(v) and not gy.has(v):
				gy.append(v)
	return [gx, gy]


## Debug / capture helper: lays every item out in tidy rows by type.
func auto_arrange(instant := false) -> void:
	if phase != Phase.SORTING:
		return
	if _held:
		drop_held(true)
	var order := Layouts.sort_by_type(items)
	var sizes: Array[Vector2i] = []
	var groups := []
	for it in order:
		sizes.append(it.base_size)
		groups.append(it.category())
	var rects := Layouts.fit_desk(sizes, groups, Desk.COLS, Desk.ROWS)
	for it in items:
		it.placed = false
	for k in order.size():
		var it: DeskItem = order[k]
		it.cell = rects[k].position
		it.placed = true
		var target := Desk.centre_of(rects[k].position, rects[k].size)
		if instant:
			it.stop_motion()
			it.position = target
			it.rotation = 0.0
			it.velocity = Vector2.ZERO
			it.spin = 0.0
			continue
		var t := it.motion()
		t.tween_interval(k * 0.09)
		t.tween_property(it, "lift", 1.0, 0.06)
		t.tween_property(it, "position", target, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(it, "rotation", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(it, "lift", 0.0, 0.06)
		t.tween_callback(_after_snap.bind(it, true, true))
	if instant:
		_update_live_score()


# --- input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.INTRO and (event.is_action_pressed(&"action_primary")
			or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		get_viewport().set_input_as_handled()
		begin_tip()
		return
	if not _interactive():
		return
	if event is InputEventMouseMotion:
		_set_pad_mode(false)
		return
	var handled := true
	if event is InputEventMouseButton:
		_set_pad_mode(false)
		var world := get_global_mouse_position()
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					grab(item_at(world), world)
				MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP:
					rotate_item(_held if _held else item_at(world), 1)
				MOUSE_BUTTON_WHEEL_DOWN:
					rotate_item(_held if _held else item_at(world), -1)
				_:
					handled = false
		elif event.button_index == MOUSE_BUTTON_LEFT and _held:
			drop_held()
		else:
			handled = false
	elif event.is_action_pressed(&"finish_job"):
		if phase == Phase.SORTING:
			take_photo()
		else:
			pack_rest()
	elif event.is_action_pressed(&"rotate_cw"):
		rotate_item(_held if _held else _hovered, 1)
	elif event.is_action_pressed(&"rotate_ccw"):
		rotate_item(_held if _held else _hovered, -1)
	elif event.is_action_pressed(&"action_primary"):
		_set_pad_mode(true)
		if _held:
			drop_held()
		else:
			grab(_hovered if _hovered else item_at(_cursor), _cursor)
	else:
		handled = false
		if not (event is InputEventJoypadMotion):  # the stick drives the cursor in _process
			for a in [&"move_left", &"move_right", &"move_up", &"move_down"]:
				if event.is_action_pressed(a, true):
					_set_pad_mode(true)
					_step(_dir_of(a))
					handled = true
					break
	if handled:
		get_viewport().set_input_as_handled()


func _dir_of(action: StringName) -> Vector2i:
	match action:
		&"move_left": return Vector2i.LEFT
		&"move_right": return Vector2i.RIGHT
		&"move_up": return Vector2i.UP
	return Vector2i.DOWN


## D-pad / keys: nudge the held item one cell, or jump the cursor to the next item that way.
func _step(dir: Vector2i) -> void:
	if _held:
		_cursor += Vector2(dir) * Desk.CELL
		_cursor = _clamp_cursor(_cursor)
		Audio.play_sfx(Sfx.get_stream("tick"), -12.0, 0.05)
		return
	var best: DeskItem
	var best_score := INF
	for it in items:
		if not it.visible:
			continue
		var d := it.position - _cursor
		if d.length() < 4.0:
			continue
		var along := d.normalized().dot(Vector2(dir))
		if along < 0.4:
			continue
		var s := d.length() * (2.0 - along)
		if s < best_score:
			best_score = s
			best = it
	if best:
		_cursor = best.position
		_set_hover(best)


func _set_pad_mode(on: bool) -> void:
	if _pad_mode == on:
		return
	_pad_mode = on
	_refresh_hint()
	cursor_node.queue_redraw()


func _clamp_cursor(p: Vector2) -> Vector2:
	var r := Desk.rect_px()
	if phase == Phase.PACKING:
		r = r.merge(pack_rect_px())
	return p.clamp(r.position, r.end)


func _set_hover(it: DeskItem) -> void:
	if _hovered == it:
		return
	if _hovered:
		_hovered.hover = false
	_hovered = it
	if it:
		it.hover = true


# --- per-frame ----------------------------------------------------------------

func _process(delta: float) -> void:
	_read_stick(delta)
	if not _pad_mode:
		_cursor = get_global_mouse_position()
	cursor_node.position = _cursor
	cursor_node.visible = _pad_mode and _interactive()
	if phase == Phase.PACKING and not _closing:
		var before_s := int(_pack_time)
		_pack_time += delta
		if int(_pack_time) != before_s:
			_update_pack_status()
	if _closing and container_box.zip > 0.0:
		var edge := container_box.zip_edge_x()
		for it in items:
			if it.packed and it.visible and it.position.x < edge:
				it.visible = false
	if _interactive():
		if _held:
			var target := _cursor + _grab_offset
			var before := _held.position
			_held.position = _held.position.lerp(target, 1.0 - exp(-26.0 * delta))
			var vx := (_held.position.x - before.x) / maxf(delta, 0.001)
			_held.tilt = lerpf(_held.tilt, clampf(vx * 0.0004, -0.22, 0.22), 1.0 - exp(-12.0 * delta))
			var size := _held.grid_size()
			var cell: Vector2i = landing(_held, _held.position, size)[0]
			var g := _guides(Rect2i(cell, size), _held)
			desk.show_ghost(Rect2i(cell, size), g[0], g[1])
		elif not _pad_mode:
			_set_hover(item_at(_cursor))
		elif _hovered and _hovered.position.distance_to(_cursor) > 6.0:
			_set_hover(item_at(_cursor))
	_update_item_tip()
	_shake = move_toward(_shake * exp(-7.0 * delta), 0.0, delta)
	camera.offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake


## Item name in the HUD (>= 28 px on screen) above the held or hovered item.
func _update_item_tip() -> void:
	var it := _held if _held else _hovered
	if it == null or not _interactive() or not it.visible:
		hud.hide_item_tip()
		return
	var top := it.position - Vector2(0, it.half_extents().y + 4.0 + 10.0 * it.lift)
	hud.show_item_tip(it.display_name(), get_viewport().get_canvas_transform() * top)


func _read_stick(delta: float) -> void:
	if not _interactive():
		return
	var v := Vector2.ZERO
	for d in Input.get_connected_joypads():
		var s := Vector2(Input.get_joy_axis(d, JOY_AXIS_LEFT_X), Input.get_joy_axis(d, JOY_AXIS_LEFT_Y))
		if s.length() > v.length():
			v = s
	if v.length() < STICK_DEADZONE:
		return
	_set_pad_mode(true)
	v = v.normalized() * inverse_lerp(STICK_DEADZONE, 1.0, minf(v.length(), 1.0))
	_cursor = _clamp_cursor(_cursor + v * v.length() * CURSOR_SPEED * delta)


func _physics_process(delta: float) -> void:
	if phase == Phase.TIPPING:
		_tip_time += delta
		_pour_timer -= delta
		while not _pour.is_empty() and _pour_timer <= 0.0:
			_spawn_from_container(_pour.pop_front())
			_pour_timer += 0.32 / maxf(1.0, items.size())
	if phase == Phase.TIPPING or phase == Phase.SORTING:
		_step_loose(delta)
	if phase == Phase.TIPPING and _pour.is_empty() and _tip_time > 0.9 and (_all_resting() or _tip_time > 2.6):
		_end_tip()


## Loose items slide, spin, bounce off the mat edge and push each other (and out of placed items).
func _step_loose(dt: float) -> void:
	var loose: Array[DeskItem] = []
	for it in items:
		if it.visible and not it.placed and not it.held:
			loose.append(it)
	var mat := Desk.rect_px()
	for it in loose:
		it.position += it.velocity * dt
		it.rotation += it.spin * dt
		it.velocity *= exp(-3.4 * dt)
		it.spin *= exp(-3.0 * dt)
		var e := it.half_extents()
		var hit := false
		if it.position.x - e.x < mat.position.x:
			it.position.x = mat.position.x + e.x
			it.velocity.x = absf(it.velocity.x) * 0.45
			hit = true
		elif it.position.x + e.x > mat.end.x:
			it.position.x = mat.end.x - e.x
			it.velocity.x = -absf(it.velocity.x) * 0.45
			hit = true
		if it.position.y - e.y < mat.position.y:
			it.position.y = mat.position.y + e.y
			it.velocity.y = absf(it.velocity.y) * 0.45
			hit = true
		elif it.position.y + e.y > mat.end.y:
			it.position.y = mat.end.y - e.y
			it.velocity.y = -absf(it.velocity.y) * 0.45
			hit = true
		if hit and it.velocity.length() > 220.0:
			it.spin += _rng.randf_range(-4.0, 4.0)
			_shake = maxf(_shake, 3.0)
			Audio.play_sfx(Sfx.get_stream("click"), -12.0, 0.2, 0.6)
	# Soft separation so the pile spreads into a readable mess instead of a stack.
	for i in loose.size():
		var a := loose[i]
		var ra := minf(a.half_extents().x, a.half_extents().y) + 6.0
		for j in range(i + 1, loose.size()):
			var b := loose[j]
			var rb := minf(b.half_extents().x, b.half_extents().y) + 6.0
			var d := b.position - a.position
			var dist := d.length()
			if dist < ra + rb and dist > 0.01:
				var push := d / dist * (ra + rb - dist) * 0.25
				a.position -= push
				b.position += push
		for other in items:
			if other.placed and other.visible:
				var r := Rect2(Desk.cell_to_px(Vector2(other.cell)), Vector2(other.grid_size()) * Desk.CELL).grow(ra * 0.6)
				if r.has_point(a.position):
					_push_out(a, r)


func _push_out(it: DeskItem, r: Rect2) -> void:
	var p := it.position
	var dl := p.x - r.position.x
	var dr := r.end.x - p.x
	var du := p.y - r.position.y
	var dd := r.end.y - p.y
	var m := minf(minf(dl, dr), minf(du, dd))
	var push := Vector2.ZERO
	if m == dl:
		push = Vector2(-dl, 0)
	elif m == dr:
		push = Vector2(dr, 0)
	elif m == du:
		push = Vector2(0, -du)
	else:
		push = Vector2(0, dd)
	it.position += push * 0.5
	it.velocity += push.normalized() * 40.0


## A drop kicks loose items that were under it out of the way.
func _bump_loose_from(it: DeskItem) -> void:
	var r := Rect2(Desk.cell_to_px(Vector2(it.cell)), Vector2(it.grid_size()) * Desk.CELL).grow(8)
	for other in items:
		if other != it and other.visible and not other.placed and not other.held and r.has_point(other.position):
			var away := (other.position - it.position).normalized()
			if away == Vector2.ZERO:
				away = Vector2.RIGHT
			other.velocity += away * 520.0
			other.spin += _rng.randf_range(-6.0, 6.0)


func _all_resting() -> bool:
	for it in items:
		if it.visible and not it.placed and (it.velocity.length() > 14.0 or absf(it.spin) > 0.4):
			return false
	return true


# --- juice helpers -------------------------------------------------------------

func _make_puff() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.damping_min = 120.0
	p.damping_max = 200.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.color = Color(1, 1, 1, 0.55)
	p.z_index = 5
	return p


func _puff(it: DeskItem) -> void:
	var p := _puffs[_next_puff]
	_next_puff = (_next_puff + 1) % _puffs.size()
	p.position = it.position
	p.emission_rect_extents = Vector2(it.grid_size()) * Desk.CELL * 0.5
	p.restart()


func _draw_cursor() -> void:
	cursor_node.draw_circle(Vector2.ZERO, 14.0, Color(1, 1, 1, 0.18))
	cursor_node.draw_arc(Vector2.ZERO, 14.0, 0, TAU, 32, Color(1, 1, 1, 0.9), 3.0)
	cursor_node.draw_circle(Vector2.ZERO, 3.0, Color.WHITE)


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _wait(seconds: float) -> void:
	await create_tween().tween_interval(seconds).finished


# --- autoplay (debug builds only: greybox capture) -------------------------------

## `godot --path game res://scenes/game.tscn -- --autoplay [--job=3] [--seed=7]` plays one job
## by itself and quits:
## tip, settle, knolling timelapse, photo, reveal, pack. Used with --write-movie.
func _run_autoplay() -> void:
	await _wait(0.9)
	begin_tip()
	while phase == Phase.TIPPING:
		await _wait(0.1)
	await _wait(0.8)
	auto_arrange()
	await _wait(items.size() * 0.09 + 0.8)
	take_photo()
	await _wait(4.0)
	pack_back()
	while phase != Phase.DONE:
		await _wait(0.1)
	await _wait(1.0)
	get_tree().quit()
