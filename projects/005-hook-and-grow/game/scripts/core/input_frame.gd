class_name InputFrame
extends RefCounted
## One fixed step of player intent. The scene builds it from devices; tests and the bot build it directly.

var move := Vector2.ZERO        # left stick / WASD, length <= 1
var aim := Vector2.RIGHT        # unit vector from the player towards the cursor / right stick
var hook_pressed := false       # throw, or yank while something is on the line
var dodge_pressed := false


static func make(move_v := Vector2.ZERO, aim_v := Vector2.RIGHT, hook := false, dodge := false) -> InputFrame:
	var f := InputFrame.new()
	f.move = move_v
	f.aim = aim_v
	f.hook_pressed = hook
	f.dodge_pressed = dodge
	return f
