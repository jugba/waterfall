extends GutTest
## Drop-in asset hooks: optional item sprites (fallback = coloured rectangle) and named SFX /
## music ids that real files can replace without code changes.


func test_item_sprites_exist_and_match_footprint() -> void:
	var with_sprite := 0
	for id in Catalog.items():
		var d: Dictionary = Catalog.item(id)
		if not d.has("sprite"):
			continue
		with_sprite += 1
		var tex := DeskItem.load_sprite(d)
		assert_not_null(tex, "%s sprite loads (%s)" % [id, d["sprite"]])
		if tex:
			assert_eq(Vector2i(tex.get_size()), Vector2i(int(d["w"]), int(d["h"])) * 64, "%s: 64 px per cell" % id)
	gut.p("%d of %d items have sprites" % [with_sprite, Catalog.items().size()])
	assert_gt(with_sprite, 0)


func test_missing_or_absent_sprite_falls_back() -> void:
	assert_null(DeskItem.load_sprite({"id": "x"}))
	assert_null(DeskItem.load_sprite({"id": "x", "sprite": "res://assets/art/items/nope@2x.png"}))
	var it := DeskItem.new()
	it.setup({"id": "x", "name": "X", "w": 2, "h": 1, "colour": "red", "sprite": "res://nope.png"})
	assert_false(it.has_sprite())
	it.free()


func test_every_sfx_call_uses_a_registered_id() -> void:
	var rx := RegEx.create_from_string("Sfx\\.get_stream\\(\"([a-z_0-9]+)\"\\)")
	var used := {}
	for d in ["res://scripts", "res://ui", "res://autoload"]:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				for m in rx.search_all(FileAccess.get_file_as_string("%s/%s" % [d, f])):
					used[m.get_string(1)] = true
					assert_true(Sfx.IDS.has(m.get_string(1)), "%s: '%s' is in Sfx.IDS" % [f, m.get_string(1)])
	assert_gt(used.size(), 8)


func test_every_sfx_id_has_a_stream() -> void:
	for id in Sfx.IDS:
		var s := Sfx.get_stream(id)
		assert_not_null(s, id)
		if s is AudioStreamWAV:
			assert_gt(s.data.size(), 100, "%s placeholder has samples" % id)


func test_music_is_optional() -> void:
	for screen in Sfx.MUSIC:
		if Sfx.music(screen) == null:
			assert_eq(Sfx.files_for("no_such_sound").size(), 0)
	Sfx.play_music("no_such_screen")  # must be a silent no-op
	pass_test("missing music is a no-op")


func test_audio_plan_lists_every_hook() -> void:
	var plan := ProjectSettings.globalize_path("res://").path_join("../audio/audio-plan.md")
	assert_true(FileAccess.file_exists(plan), "audio/audio-plan.md exists")
	var text := FileAccess.get_file_as_string(plan)
	for id in Sfx.IDS:
		assert_true(text.contains("`%s`" % id), "audio plan lists sfx `%s`" % id)
	for screen in Sfx.MUSIC:
		assert_true(text.contains("`%s`" % screen), "audio plan lists music `%s`" % screen)
