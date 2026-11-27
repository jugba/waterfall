extends SceneTree
## Tuning aid (not a test): runs the pacing bot over a few seeds and prints milestone times.
##   godot --headless --path game -s res://tests/tools/pace_report.gd -- [seeds] [max_seconds]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds := int(args[0]) if args.size() > 0 else 4
	var max_s := float(args[1]) if args.size() > 1 else 900.0
	for s in seeds:
		var t0 := Time.get_ticks_msec()
		var sim := ArenaSim.new({}, 100 + s)
		var bot := Bot.new(200 + s)
		var wave_t := {}
		var size_t := {}
		while sim.time < max_s and not sim.won:
			if not sim.pending_choice.is_empty():
				sim.choose_evolution(0)
			sim.step(bot.think(sim))
			for e in sim.events:
				if e["type"] == "wave":
					wave_t[e["wave"]] = snappedf(sim.time, 1)
			for m in [5, 8, 10, 15, 20, 25, 30, 36]:
				if sim.size >= m and not size_t.has(m):
					size_t[m] = snappedf(sim.time, 1)
		print("seed %d: evo=%s boss_spawn=%.0f hookable=%.0f won=%.0f size=%.1f meals=%d deaths=%d traits=%s ms=%d" % [
			s, str(sim.evolution_times.map(func(x): return snappedf(x, 1))), sim.boss_spawned_at,
			sim.boss_hookable_at, sim.won_at, sim.size, sim.meals, sim.deaths, str(sim.traits),
			Time.get_ticks_msec() - t0])
		print("   waves: ", wave_t, "\n   sizes: ", size_t)
	quit(0)
