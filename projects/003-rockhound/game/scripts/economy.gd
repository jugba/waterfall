extends RefCounted
## Rockhound game state and rules: rarity rolls with pity, upgrades, values, collection, depth.
## Pure logic (no nodes) so tests can drive it. Balance numbers live in res://data/balance.json.
##
## Usage: var eco := Economy.new(); var g := eco.dig_geode(); var c := eco.crack(g); eco.sell(c)

const DATA_PATH := "res://data/balance.json"
const RARE := 2
const EPIC := 3

var data: Dictionary
var tiers: Array
var crystals: Array
var sets: Array
var upgrades: Array
var rng := RandomNumberGenerator.new()

# --- state (saved) ---
var money := 0.0
var lifetime_money := 0.0
var levels: Dictionary = {}       # upgrade id -> level
var collection: Dictionary = {}   # crystal id -> count found
var since_rare := 0               # geodes rolled since the last rare-or-better
var since_epic := 0
var depth := 0
var chunks_broken := 0            # in the current rock face
var geodes_cracked := 0
var tray: Array = []              # geodes waiting: {"tier": int, "hint": int}
var play_seconds := 0.0


func _init(seed_value: int = -1) -> void:
	data = load_data()
	tiers = data["tiers"]
	crystals = data["crystals"]
	sets = data["sets"]
	upgrades = data["upgrades"]
	for u in upgrades:
		levels[u["id"]] = 0
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


static func load_data() -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(DATA_PATH)) != OK or not (json.data is Dictionary):
		push_error("Economy: cannot parse %s" % DATA_PATH)
		return {}
	return json.data


# --- rarity -------------------------------------------------------------------

func tier_weights() -> Array[float]:
	var luck := 1.0 + float(data["luck_per_level"]) * level("luck")
	var out: Array[float] = []
	for i in tiers.size():
		out.append(float(tiers[i]["weight"]) * pow(luck, i))
	return out


## Probability of each tier without pity (for odds display and tests).
func tier_odds() -> Array[float]:
	var w := tier_weights()
	var total := 0.0
	for x in w:
		total += x
	var out: Array[float] = []
	for x in w:
		out.append(x / total)
	return out


## Rolls a tier, applying pity: after `rare_after` geodes with no rare+, the next is rare+;
## after `epic_after` with no epic+, the next is epic+.
func roll_tier() -> int:
	since_rare += 1
	since_epic += 1
	var floor_tier := 0
	if since_epic >= int(data["pity"]["epic_after"]):
		floor_tier = EPIC
	elif since_rare >= int(data["pity"]["rare_after"]):
		floor_tier = RARE
	var w := tier_weights()
	var total := 0.0
	for i in range(floor_tier, w.size()):
		total += w[i]
	var r := rng.randf() * total
	var t := w.size() - 1
	for i in range(floor_tier, w.size()):
		r -= w[i]
		if r < 0.0:
			t = i
			break
	if t >= RARE:
		since_rare = 0
	if t >= EPIC:
		since_epic = 0
	return t


## The shell shows the true tier most of the time, otherwise one lower: a sparkly shell is a
## promise of at least that tier.
func shell_hint(tier: int) -> int:
	if tier > 0 and rng.randf() > float(data["shell_hint_accuracy"]):
		return tier - 1
	return tier


func crystals_of_tier(tier: int) -> Array:
	return crystals.filter(func(c): return int(c["tier"]) == tier)


func pick_crystal(tier: int) -> Dictionary:
	var pool := crystals_of_tier(tier)
	return pool[rng.randi() % pool.size()]


# --- rock ---------------------------------------------------------------------

func dig_power() -> int:
	return 1 + level("pick")


func chunk_hp() -> int:
	var r: Dictionary = data["rock"]
	return maxi(1, roundi(float(r["base_chunk_hp"]) * pow(float(r["hp_growth_per_depth"]), depth)))


func chunks_per_face() -> int:
	return int(data["rock"]["chunks_per_face"])


func tray_size() -> int:
	return int(data["rock"]["tray_size"])


## How many geodes a broken chunk drops: 1 plus Rich Vein's chance of extras.
func geodes_per_chunk() -> int:
	var extra := 0.2 * level("vein")
	var n := 1 + int(floor(extra))
	if rng.randf() < extra - floor(extra):
		n += 1
	return n


## A new geode: rolled now so its shell can hint at what is inside.
func new_geode() -> Dictionary:
	var t := roll_tier()
	return {"tier": t, "hint": shell_hint(t)}


## Call when a chunk breaks. Returns the geodes dropped. Advances depth when the face is cleared.
## Geodes go to the tray; if it is full, the plainest-looking one is bulk-sold (returned in
## "bulk_sold" with its value) so idle digging still earns.
func break_chunk() -> Dictionary:
	var dropped: Array = []
	var bulk := 0.0
	for i in geodes_per_chunk():
		var g := new_geode()
		dropped.append(g)
		tray.append(g)
		if tray.size() > tray_size():
			var worst := 0
			for k in tray.size():
				if int(tray[k]["hint"]) < int(tray[worst]["hint"]):
					worst = k
			var sold: Dictionary = tray[worst]
			tray.remove_at(worst)
			var v := bulk_value(int(sold["tier"]))
			bulk += v
			add_money(v)
	chunks_broken += 1
	var new_depth := false
	if chunks_broken >= chunks_per_face():
		chunks_broken = 0
		depth += 1
		new_depth = true
	return {"geodes": dropped, "bulk_sold": bulk, "new_depth": new_depth}


func bulk_value(tier: int) -> float:
	return float(tiers[tier]["value"]) * depth_mult() * set_mult() * float(data["rock"]["bulk_sell_factor"])


func take_from_tray() -> Dictionary:
	if tray.is_empty():
		return {}
	return tray.pop_front()


# --- cracking and value ---------------------------------------------------------

func strikes_needed(tier: int) -> int:
	return int(tiers[tier]["strikes"])


## Opens a geode: picks the crystal and its value. Records it in the collection.
func crack(geode: Dictionary) -> Dictionary:
	var tier := int(geode["tier"])
	var c := pick_crystal(tier)
	var is_new := not collection.has(c["id"])
	var sets_before := completed_sets()
	collection[c["id"]] = int(collection.get(c["id"], 0)) + 1
	geodes_cracked += 1
	var newly: Array = completed_sets().filter(func(s): return not sets_before.has(s))
	return {
		"id": c["id"], "name": c["name"], "tier": tier, "color": c["color"],
		"value": crystal_value(c), "is_new": is_new, "sets_completed": newly,
	}


func crystal_value(c: Dictionary) -> float:
	return float(tiers[int(c["tier"])]["value"]) * float(c["value_mult"]) * depth_mult() * set_mult()


func depth_mult() -> float:
	return pow(float(data["rock"]["value_growth_per_depth"]), depth)


func completed_sets() -> Array:
	var out: Array = []
	for s in sets:
		if s["members"].all(func(m): return collection.has(m)):
			out.append(s["id"])
	return out


func set_mult() -> float:
	var m := 1.0
	for s in sets:
		if s["members"].all(func(id): return collection.has(id)):
			m += float(s["bonus"])
	return m


## Polish multiplier for a release at `fill` (0..1+). Perfect inside the zone; partial below;
## overshooting scratches the stone.
func polish_mult(fill: float) -> float:
	var L := level("polish")
	if L <= 0:
		return 1.0
	var p: Dictionary = data["polish"]
	var best := float(p["base_mult"]) + float(p["mult_per_level"]) * (L - 1)
	if fill > 1.0:
		return 1.0 + (best - 1.0) * 0.2
	if fill >= float(p["zone_start"]) and fill <= float(p["zone_end"]):
		return best
	return 1.0 + (best - 1.0) * clampf(fill, 0.0, 1.0) * 0.6


func is_perfect_polish(fill: float) -> bool:
	var p: Dictionary = data["polish"]
	return fill >= float(p["zone_start"]) and fill <= float(p["zone_end"])


func sell(crystal: Dictionary, polish := 1.0) -> float:
	var v := float(crystal["value"]) * polish
	add_money(v)
	return v


func add_money(v: float) -> void:
	money += v
	lifetime_money += v


# --- upgrades -------------------------------------------------------------------

func level(id: String) -> int:
	return int(levels.get(id, 0))


func upgrade_def(id: String) -> Dictionary:
	for u in upgrades:
		if u["id"] == id:
			return u
	return {}


func upgrade_cost(id: String) -> float:
	var u := upgrade_def(id)
	return floor(float(u["base_cost"]) * pow(float(u["growth"]), level(id)))


func is_maxed(id: String) -> bool:
	return level(id) >= int(upgrade_def(id).get("max", 99))


func can_buy(id: String) -> bool:
	return not is_maxed(id) and money >= upgrade_cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	money -= upgrade_cost(id)
	levels[id] = level(id) + 1
	return true


## The cheapest upgrade not yet maxed: the "next goal" shown on screen.
func next_goal() -> String:
	var best := ""
	for u in upgrades:
		if is_maxed(u["id"]):
			continue
		if best == "" or upgrade_cost(u["id"]) < upgrade_cost(best):
			best = u["id"]
	return best


func auto_digs_per_second() -> float:
	return 0.8 * level("auto")


## Expected value of one geode at current luck/depth/sets (no pity, no polish).
func expected_geode_value() -> float:
	var odds := tier_odds()
	var ev := 0.0
	for t in tiers.size():
		var pool := crystals_of_tier(t)
		var avg := 0.0
		for c in pool:
			avg += crystal_value(c)
		ev += odds[t] * avg / maxf(1.0, pool.size())
	return ev


## Idle income estimate from the Auto-Digger, assuming its geodes are bulk-sold.
func idle_income_per_second() -> float:
	var chunks_per_s := auto_digs_per_second() * dig_power() / float(chunk_hp())
	var geodes_per_chunk_avg := 1.0 + 0.2 * level("vein")
	return chunks_per_s * geodes_per_chunk_avg * expected_geode_value() * float(data["rock"]["bulk_sell_factor"])


# --- save -----------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"money": money, "lifetime_money": lifetime_money, "levels": levels.duplicate(),
		"collection": collection.duplicate(), "since_rare": since_rare, "since_epic": since_epic,
		"depth": depth, "chunks_broken": chunks_broken, "geodes_cracked": geodes_cracked,
		"tray": tray.duplicate(true), "play_seconds": play_seconds,
	}


func from_dict(d: Dictionary) -> void:
	money = float(d.get("money", 0.0))
	lifetime_money = float(d.get("lifetime_money", money))
	var lv: Dictionary = d.get("levels", {})
	for u in upgrades:
		levels[u["id"]] = int(lv.get(u["id"], 0))
	collection.clear()
	var col: Dictionary = d.get("collection", {})
	for k in col:
		collection[str(k)] = int(col[k])
	since_rare = int(d.get("since_rare", 0))
	since_epic = int(d.get("since_epic", 0))
	depth = int(d.get("depth", 0))
	chunks_broken = int(d.get("chunks_broken", 0))
	geodes_cracked = int(d.get("geodes_cracked", 0))
	play_seconds = float(d.get("play_seconds", 0.0))
	tray.clear()
	for g in d.get("tray", []):
		if g is Dictionary:
			var t := clampi(int(g.get("tier", 0)), 0, tiers.size() - 1)
			tray.append({"tier": t, "hint": clampi(int(g.get("hint", t)), 0, t)})
