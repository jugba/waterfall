class_name Growth
extends RefCounted
## Pure growth rules: mass -> size -> stats, meals, traits. No nodes, so tests call these directly.
##
## Size is the number shown to the player ("Size 12"). Body radius in px = size * px_per_size.
## Mass grows by eating; size = start_size * mass^(1/3), so eating something your own size
## grows you ~26% and snacks grow you a few percent (the agar.io-style curve that keeps every
## meal visible but slows down as you get huge).

const TRAITS: Array[String] = ["armour", "speed", "damage", "pierce"]


static func size_from_mass(b: Dictionary, mass: float) -> float:
	var p: Dictionary = b["player"]
	return float(p["start_size"]) * pow(maxf(mass, 0.0001) / float(p["start_mass"]), float(p["size_exponent"]))


static func mass_from_size(b: Dictionary, size: float) -> float:
	var p: Dictionary = b["player"]
	return float(p["start_mass"]) * pow(size / float(p["start_size"]), 1.0 / float(p["size_exponent"]))


## Mass gained by an eater of `eater_size` eating an enemy of `enemy_size` and type `kind`.
## Efficiency falls off as you grow, so early meals give quick growth spurts and late growth
## needs the bigger prey (and the boss) instead of snowballing.
static func meal_mass(b: Dictionary, kind: String, enemy_size: float, eater_size := -1.0) -> float:
	var p: Dictionary = b["player"]
	var meat: float = b["enemies"][kind].get("meat", 1.0)
	var eff: float = float(p["eat_efficiency"])
	if eater_size > 0.0:
		eff *= pow(float(p["start_size"]) / maxf(eater_size, float(p["start_size"])),
			float(p.get("efficiency_size_decay", 0.0)))
	return mass_from_size(b, enemy_size) * meat * eff


static func radius(b: Dictionary, size: float) -> float:
	return size * float(b["px_per_size"])


## World-scale factor: 1.0 at the start size. Speeds, hook speed, reel and camera zoom use it, so
## the game feels the same on screen at any size while the world visibly shrinks around you.
static func scale(b: Dictionary, size: float) -> float:
	var p: Dictionary = b["player"]
	return pow(size / float(p["start_size"]), float(p["speed_size_exponent"]))


static func can_hook(b: Dictionary, player_size: float, enemy_size: float) -> bool:
	return enemy_size <= player_size * float(b["hook"]["catch_ratio"]) + 0.0001


## Smallest player size that can hook an enemy of this size.
static func size_needed(b: Dictionary, enemy_size: float) -> float:
	return enemy_size / float(b["hook"]["catch_ratio"])


## Trait level from how many of that archetype you have eaten: the first one gives level 1 at once,
## then 3 -> 2, 12 -> 3, 27 -> 4, 48 -> 5, 75 -> 6 (square-root steps, so body parts keep
## appearing across the whole ~10-minute run instead of maxing out by wave 5).
static func trait_level(eaten: int, cap: int) -> int:
	if eaten <= 0:
		return 0
	return mini(1 + int(floor(sqrt(eaten / 3.0) + 0.0001)), cap)


static func stack(traits: Dictionary, t: String, cap: int) -> int:
	return trait_level(int(traits.get(t, 0)), cap)


## All derived stats for a size + trait stacks + evolved forms.
static func stats(b: Dictionary, size: float, traits: Dictionary, forms: Dictionary = {}) -> Dictionary:
	var p: Dictionary = b["player"]
	var h: Dictionary = b["hook"]
	var tr: Dictionary = b["traits"]
	var cap: int = int(tr["cap"])
	var k := scale(b, size)
	var r := radius(b, size)
	var arm := stack(traits, "armour", cap)
	var spd := stack(traits, "speed", cap)
	var dmg := stack(traits, "damage", cap)
	var prc := stack(traits, "pierce", cap)
	var range_mult := 1.0 + float(tr["pierce_range_bonus"]) * prc \
		+ float(b["evolution"]["long_range_bonus"]) * int(forms.get("long", 0))
	var start_r := radius(b, float(p["start_size"]))
	var base_range := float(h["base_range"]) + float(h["range_per_px_radius"]) * start_r
	var hook_range := (float(h["base_range"]) + float(h["range_per_px_radius"]) * r) * range_mult
	var hscale := hook_range / base_range  # hook world scale
	return {
		"size": size,
		"radius": r,
		"scale": k,
		"hook_scale": hscale,
		"speed": float(p["base_speed"]) * k * (1.0 + float(tr["speed_bonus"]) * spd),
		"hp_max": float(p["hp_base"]) + float(p["hp_per_size"]) * size,
		"damage_taken": maxf(0.4, 1.0 - float(tr["armour_damage_cut"]) * arm),
		"dodge_cooldown": float(p["dodge_cooldown"]) * maxf(0.5, 1.0 - float(tr["dodge_cd_cut"]) * spd),
		"hook_range": hook_range,
		"hook_speed": float(h["speed"]) * hscale,
		"return_speed": float(h["return_speed"]) * hscale,
		"hook_radius": float(h["hook_radius"]) * sqrt(hscale),
		"auto_reel": float(h["auto_reel"]) * hscale,
		"yank": float(h["yank_impulse"]) * hscale * (1.0 + float(tr["damage_yank_bonus"]) * dmg),
		"shockwave": 0.0 if dmg == 0 else r + float(tr["damage_shockwave_px"]) * dmg * k,
		"spike_proof": arm > 0 or prc > 0,
		"pierce": prc > 0,
	}
