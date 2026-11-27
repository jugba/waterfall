class_name ArenaDriver
extends RefCounted
## The shared, view-independent run loop: turns device state into InputFrames (mouse or right-stick
## aim, controller aim assist, press buffering), applies hitstop, lets the Bot or a scripted input
## play, and steps the ArenaSim. Both the 2D arena (scripts/game.gd) and the 3D arena
## (scripts/game_3d.gd) own one, so the same inputs give the same gameplay in either view; the views
## only draw the sim and react to its events (connect `stepped`).
##
## Hitstop lives here, not in the views, because it changes *when* the sim steps.

signal stepped           ## sim.step() ran; sim.events holds this step's events
signal auto_chose        ## the bot picked an evolution; sim.events holds the "evolve" event

const HOOK_BUFFER := 0.15
const DODGE_BUFFER := 0.12
const PAD_AIM_DEADZONE := 0.35
const ASSIST_CONE_DEG := 12.0

var sim: ArenaSim
var bot: Bot = null
## Optional: func(driver) -> InputFrame. Tests use it to feed scripted inputs through a scene.
var script_input: Callable
var hitstop := 0.0
var hook_buffer := 0.0
var dodge_buffer := 0.0
var use_pad_aim := false
var ticks := 0


func _init(s: ArenaSim) -> void:
	sim = s


## Call once per physics frame. `blocked` = a modal panel (evolution / victory) is open.
## `read_input` = func(driver) -> InputFrame, used when neither the bot nor a script plays.
func tick(delta: float, blocked: bool, read_input: Callable) -> void:
	ticks += 1
	hook_buffer -= delta
	dodge_buffer -= delta
	if blocked:
		hook_buffer = 0.0
		dodge_buffer = 0.0
		return
	if hitstop > 0.0:
		hitstop -= delta
		return
	var f: InputFrame
	if bot != null:
		if not sim.pending_choice.is_empty():
			sim.choose_evolution(0)
			auto_chose.emit()
		f = bot.think(sim)
	elif script_input.is_valid():
		f = script_input.call(self)
	else:
		f = read_input.call(self)
	if f.hook_pressed:
		hook_buffer = 0.0
	if f.dodge_pressed:
		dodge_buffer = 0.0
	sim.step(f)
	_apply_hitstop()
	stepped.emit()


func press_hook() -> void:
	hook_buffer = HOOK_BUFFER


func press_dodge() -> void:
	dodge_buffer = DODGE_BUFFER


## Reads the "just pressed" hook/dodge actions into the press buffers.
func poll_buttons() -> void:
	if Input.is_action_just_pressed(&"hook"):
		press_hook()
	if Input.is_action_just_pressed(&"dodge"):
		press_dodge()


## Mouse motion switches to mouse aim; a pushed stick switches to pad aim.
func on_input_event(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		use_pad_aim = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		use_pad_aim = true


## The InputFrame for the current device state. `mouse_world` is the cursor on the play plane in
## sim coordinates (2D: the canvas mouse position; 3D: the camera ray hit on the XZ plane).
func read_devices(mouse_world: Vector2) -> InputFrame:
	var move := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length() > PAD_AIM_DEADZONE:
		use_pad_aim = true
	return make_frame(sim, move, stick, use_pad_aim, mouse_world, Settings.aim_assist,
		hook_buffer > 0.0, dodge_buffer > 0.0)


## Pure: device values -> InputFrame (no Input singleton), so tests can check aim mapping.
static func make_frame(s: ArenaSim, move: Vector2, stick: Vector2, pad_aim: bool, mouse_world: Vector2,
		assist_on: bool, hook: bool, dodge: bool) -> InputFrame:
	var f := InputFrame.new()
	f.move = move
	if pad_aim:
		if stick.length() > PAD_AIM_DEADZONE:
			f.aim = stick.normalized()
		elif move.length() > 0.3:
			f.aim = move.normalized()
		else:
			f.aim = s.aim
		if assist_on:
			f.aim = assist(s, f.aim)
	else:
		var m := mouse_world - s.pos
		f.aim = m.normalized() if m.length() > 4.0 else s.aim
	f.hook_pressed = hook
	f.dodge_pressed = dodge
	return f


## Controller aim assist: nudge onto the closest hookable prey inside a 12 degree cone.
static func assist(s: ArenaSim, aim: Vector2) -> Vector2:
	var best := aim
	var best_a := deg_to_rad(ASSIST_CONE_DEG)
	for e in s.enemies:
		if not s.hookable(e) or e.state == ArenaSim.EState.HOOKED:
			continue
		var to: Vector2 = e.pos - s.pos
		if to.length() > s.st["hook_range"] + e.radius:
			continue
		var a := absf(aim.angle_to(to))
		if a < best_a:
			best_a = a
			best = to.normalized()
	return best


## Hitstop from this step's events (catch freeze, boss bite, eat scaled by prey size).
func _apply_hitstop() -> void:
	var hk: Dictionary = sim.B["hook"]
	for ev in sim.events:
		match ev["type"]:
			"catch":
				hitstop = float(hk["hitstop_boss" if ev["boss"] else "hitstop_catch"])
			"bite":
				hitstop = 0.12
			"eat":
				var ratio: float = ev["enemy_radius"] / maxf(1.0, sim.st["radius"])
				hitstop = maxf(hitstop, float(hk["hitstop_eat"]) * (1.0 + ratio))
