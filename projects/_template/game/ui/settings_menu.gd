extends Control
## Settings screen: volume sliders, fullscreen/vsync toggles and key/controller rebinding.
## Works with mouse, keyboard and controller (focus navigation). Reused by title and pause.
## Emits `closed` when the player backs out; settings are saved on close.

signal closed

@onready var _rows: VBoxContainer = %Rows
@onready var _back: Button = %Back
@onready var _reset: Button = %Reset

var _waiting_action: StringName = &""
var _waiting_controller := false
var _waiting_button: Button = null
var _bind_buttons: Dictionary = {}  # "<action>:<0|1>" -> Button


func _ready() -> void:
	_back.pressed.connect(close)
	_reset.pressed.connect(_on_reset)
	_build()


func open() -> void:
	show()
	focus_first()


func close() -> void:
	_cancel_wait()
	Settings.save_settings()
	hide()
	closed.emit()


func focus_first() -> void:
	var first := _rows.find_next_valid_focus()
	if first:
		first.grab_focus()


func _build() -> void:
	for c in _rows.get_children():
		c.queue_free()
	_bind_buttons.clear()
	_add_header("Audio")
	for bus in Settings.BUSES:
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Settings.get_volume(bus)
		slider.custom_minimum_size.x = 320
		slider.value_changed.connect(func(v: float): Settings.set_volume(bus, v))
		_add_row(bus, [slider])
	_add_header("Display")
	var fs := CheckButton.new()
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(Settings.set_fullscreen)
	_add_row("Fullscreen", [fs])
	var vs := CheckButton.new()
	vs.button_pressed = Settings.vsync
	vs.toggled.connect(Settings.set_vsync)
	_add_row("V-Sync", [vs])
	_add_header("Controls (keyboard / controller)")
	for action in Settings.REBINDABLE_ACTIONS:
		var key_btn := _make_bind_button(action, false)
		var pad_btn := _make_bind_button(action, true)
		_add_row(String(action).capitalize(), [key_btn, pad_btn])


func _add_header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 32)
	_rows.add_child(l)


func _add_row(label: String, controls: Array) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 300
	h.add_child(l)
	for c in controls:
		h.add_child(c)
	_rows.add_child(h)


func _make_bind_button(action: StringName, controller: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size.x = 180
	b.text = Settings.binding_label(action, controller)
	b.pressed.connect(_start_wait.bind(action, controller, b))
	_bind_buttons["%s:%d" % [action, int(controller)]] = b
	return b


func _start_wait(action: StringName, controller: bool, button: Button) -> void:
	_cancel_wait()
	_waiting_action = action
	_waiting_controller = controller
	_waiting_button = button
	button.text = "Press a button..." if controller else "Press a key..."


func _cancel_wait() -> void:
	if _waiting_button:
		_waiting_button.text = Settings.binding_label(_waiting_action, _waiting_controller)
	_waiting_action = &""
	_waiting_button = null


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _waiting_action == &"":
		if event.is_action_pressed(&"ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		return
	var accepted: InputEvent = null
	if not _waiting_controller and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_wait()
			get_viewport().set_input_as_handled()
			return
		var k := InputEventKey.new()
		k.physical_keycode = event.physical_keycode
		accepted = k
	elif _waiting_controller and event is InputEventJoypadButton and event.pressed:
		var b := InputEventJoypadButton.new()
		b.button_index = event.button_index
		b.device = -1
		accepted = b
	elif _waiting_controller and event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		var m := InputEventJoypadMotion.new()
		m.axis = event.axis
		m.axis_value = signf(event.axis_value)
		m.device = -1
		accepted = m
	if accepted:
		get_viewport().set_input_as_handled()
		Settings.rebind(_waiting_action, accepted)
		_cancel_wait()
		_refresh_bind_labels()


func _refresh_bind_labels() -> void:
	for key in _bind_buttons:
		var parts: PackedStringArray = key.split(":")
		_bind_buttons[key].text = Settings.binding_label(StringName(parts[0]), parts[1] == "1")


func _on_reset() -> void:
	Settings.reset_bindings()
	_refresh_bind_labels()
