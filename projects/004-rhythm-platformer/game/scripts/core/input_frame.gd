class_name InputFrame
extends RefCounted
## One physics step of player intent. Built from the InputMap in play, or by scripts in tests/replays.

var move_x := 0.0
var down := false
var jump_pressed := false
var jump_held := false
var punch_pressed := false
var dash_pressed := false


static func from_input() -> InputFrame:
	var f := InputFrame.new()
	f.move_x = Input.get_axis(&"move_left", &"move_right")
	f.down = Input.is_action_pressed(&"move_down")
	f.jump_pressed = Input.is_action_just_pressed(&"jump")
	f.jump_held = Input.is_action_pressed(&"jump")
	f.punch_pressed = Input.is_action_just_pressed(&"punch")
	f.dash_pressed = Input.is_action_just_pressed(&"dash")
	return f
