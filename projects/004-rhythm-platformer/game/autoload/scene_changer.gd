extends CanvasLayer
## Fade-to-black scene transitions. Blocks input during the fade and unpauses the tree.
##
## Usage: SceneChanger.change_to("res://scenes/game.tscn")   (await it if you need to)

signal transition_finished

const DEFAULT_DURATION := 0.25

var busy := false
var _rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func change_to(path: String, duration := DEFAULT_DURATION) -> Error:
	if busy:
		return ERR_BUSY
	if not ResourceLoader.exists(path):
		push_error("SceneChanger: no scene at %s" % path)
		return ERR_FILE_NOT_FOUND
	busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0, duration)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	await get_tree().process_frame  # the new scene enters the tree on the next frame
	await _fade_to(0.0, duration)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	transition_finished.emit()
	return err


func _fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		_rect.color.a = alpha
		return
	var t := create_tween()
	t.tween_property(_rect, "color:a", alpha, duration)
	await t.finished
