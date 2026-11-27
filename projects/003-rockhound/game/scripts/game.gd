extends Node2D
## Placeholder gameplay scene: a player you can move. Replace with the real game.
## Shows how to use SaveGame: the player's position is restored from slot 0.

@onready var player: CharacterBody2D = $Player
@onready var hint: Label = %Hint


func _ready() -> void:
	var data := SaveGame.load_slot(0)
	if data.has("player_x"):
		player.position = Vector2(data["player_x"], data["player_y"])
	hint.text = "Move: %s / left stick    Pause: %s / Start" % [
		Settings.binding_label(&"move_up") + Settings.binding_label(&"move_left")
		+ Settings.binding_label(&"move_down") + Settings.binding_label(&"move_right"),
		Settings.binding_label(&"pause")]


func _exit_tree() -> void:
	SaveGame.save_slot(0, {"player_x": player.position.x, "player_y": player.position.y})
