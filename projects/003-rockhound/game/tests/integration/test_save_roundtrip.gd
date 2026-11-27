extends GutTest
## Progress survives a save/load round trip through SaveGame, including the game scene's own save.

const Economy := preload("res://scripts/economy.gd")

var _orig_dir: String


func before_each() -> void:
	_orig_dir = SaveGame.directory
	SaveGame.directory = "user://test_rh_saves"


func after_each() -> void:
	SaveGame.delete_slot(0)
	DirAccess.remove_absolute(SaveGame.directory)
	SaveGame.directory = _orig_dir
	Engine.time_scale = 1.0


func test_economy_round_trip() -> void:
	var a = Economy.new(5)
	a.money = 1234.5
	a.levels["pick"] = 3
	a.levels["auto"] = 2
	a.collection = {"quartz": 4, "amethyst": 1}
	a.since_rare = 7
	a.since_epic = 40
	a.depth = 2
	a.chunks_broken = 5
	a.geodes_cracked = 33
	a.tray = [{"tier": 2, "hint": 1}, {"tier": 0, "hint": 0}]
	assert_eq(SaveGame.save_slot(0, {"eco": a.to_dict()}), OK)
	var loaded := SaveGame.load_slot(0)
	var b = Economy.new(6)
	b.from_dict(loaded["eco"])
	assert_eq(b.money, 1234.5)
	assert_eq(b.level("pick"), 3)
	assert_eq(b.level("auto"), 2)
	assert_eq(b.collection, {"quartz": 4, "amethyst": 1})
	assert_eq(b.since_rare, 7)
	assert_eq(b.since_epic, 40)
	assert_eq(b.depth, 2)
	assert_eq(b.chunks_broken, 5)
	assert_eq(b.geodes_cracked, 33)
	assert_eq(b.tray, [{"tier": 2, "hint": 1}, {"tier": 0, "hint": 0}])


func test_from_dict_tolerates_bad_data() -> void:
	var b = Economy.new(1)
	b.from_dict({"levels": {"pick": 2, "bogus": 9}, "tray": [{"tier": 99, "hint": 99}, "junk"]})
	assert_eq(b.level("pick"), 2)
	assert_eq(b.tray.size(), 1)
	assert_eq(b.tray[0]["tier"], 4)
	assert_lte(b.tray[0]["hint"], 4)


func test_game_scene_saves_and_restores() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.eco.money = 777.0
	game.eco.levels["luck"] = 2
	game.free()  # _exit_tree saves
	var game2: Node = load("res://scenes/game.tscn").instantiate()
	add_child_autofree(game2)
	assert_eq(game2.eco.money, 777.0)
	assert_eq(game2.eco.level("luck"), 2)
