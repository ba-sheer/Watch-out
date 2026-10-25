extends Node

signal score_changed(score: int)
signal lives_changed(lives: int)
signal combo_changed(combo: int, multiplier: int)
signal run_started
signal run_ended
signal screen_shake(amount: float)
signal popup_requested(text: String, pos: Vector2, color: Color)
signal burst_requested(pos: Vector2, color: Color, amount: int)
signal banner_requested(text: String)

const FADE_SCENE := preload("res://fx/screen_fade/screen_fade.tscn")
const MAX_LIVES := 3
const COMBO_WINDOW := 3.0
const SAVE_PATH := "user://little_guy.cfg"
const RANKS := [
	[0, "MICROSCOPIC"],
	[300, "BARELY A SPECK"],
	[800, "CRUMB-SIZED"],
	[1500, "LITTLE GUY"],
	[3000, "SUSPICIOUSLY SPEEDY"],
	[6000, "TINY LEGEND"],
]

var score := 0
var lives := MAX_LIVES
var combo := 0
var run_time := 0.0
var crumbs_eaten := 0
var near_misses := 0
var best_combo := 0
var running := false
var new_record := false

var world_index := 0
var best_scores := {}

var worlds := [
	{
		"id": "kitchen", "name": "KITCHEN", "tagline": "clean tiles. cosy slippers.",
		"intro": "THE FLOOR IS SUSPICIOUSLY CLEAN",
		"frame": "res://assets/sprites/frame_kitchen.png",
		"footwear": {"name": "SLIPPER", "sheet": "res://assets/sprites/slipper.png", "sound": "fwump", "shake": 0.35, "dust": Pal.ROSE},
		"chaser": {
			"name": "ROOMBA", "sheet": "res://assets/sprites/roomba.png", "color": Pal.ROSE,
			"speed": 105.0, "turn": 200.0, "lifetime": 15.0, "radius": 54.0,
			"sound": "roomba", "gap": 1.2, "rotates": true, "anim": 2.5,
		},
		"floor": "res://assets/sprites/floor.png", "rug": "res://assets/sprites/rug.png",
		"frame_tint": Color(1, 1, 1),
		"speed": 190.0, "accel": 1600.0, "friction": 2200.0,
		"boot_scale": 1.0, "offset": 0.0,
		"pickups": {
			"sheet": "res://assets/sprites/pickups_kitchen.png",
			"names": ["CRUMB", "CHEESE", "GOLDEN CRUMB"],
			"colors": [Pal.PEACH, Pal.BUTTER, Pal.BUTTER],
			"stat": "CRUMBS EATEN", "interval": 1.2, "max": 6,
		},
		"decor": {"sheet": "res://assets/sprites/decor_kitchen.png", "frames": 6, "count": 12, "max_each": 3},
	},
	{
		"id": "bathroom", "name": "BATHROOM", "tagline": "wet tiles. leather sandals. you slide.",
		"intro": "THE FLOOR IS SUSPICIOUSLY WET",
		"frame": "res://assets/sprites/frame.png",
		"footwear": {"name": "SANDAL", "sheet": "res://assets/sprites/flipflop.png", "sound": "slap", "shake": 0.4, "dust": Pal.SKY},
		"chaser": {
			"name": "ROOMBA", "sheet": "res://assets/sprites/roomba.png", "color": Pal.ROSE,
			"speed": 105.0, "turn": 200.0, "lifetime": 15.0, "radius": 54.0,
			"sound": "roomba", "gap": 1.2, "rotates": true, "anim": 2.5,
		},
		"floor": "res://assets/sprites/floor_bath.png", "rug": "res://assets/sprites/rug_bath.png",
		"frame_tint": Pal.SKY.lightened(0.55),
		"speed": 190.0, "accel": 520.0, "friction": 420.0,
		"boot_scale": 1.1, "offset": 10.0,
		"pickups": {
			"sheet": "res://assets/sprites/pickups_bathroom.png",
			"names": ["BUBBLE", "SOAP", "RUBBER DUCK"],
			"colors": [Pal.SKY, Pal.ORCHID, Pal.BUTTER],
			"stat": "BUBBLES GRABBED", "interval": 1.3, "max": 5,
		},
		"decor": {"sheet": "res://assets/sprites/decor_bathroom.png", "frames": 6, "count": 9, "max_each": 2},
	},
	{
		"id": "backyard", "name": "BACKYARD", "tagline": "more boots. more berries.",
		"intro": "THE GRASS IS SUSPICIOUSLY TALL",
		"frame": "res://assets/sprites/frame.png",
		"footwear": {"name": "BOOT", "sheet": "res://assets/sprites/boot.png", "sound": "stomp", "shake": 0.55, "dust": Pal.PEACH},
		"chaser": {
			"name": "MOWER", "sheet": "res://assets/sprites/mower.png", "color": Pal.PEACH,
			"speed": 125.0, "turn": 150.0, "lifetime": 14.0, "radius": 52.0,
			"sound": "mower", "gap": 0.6, "rotates": true, "anim": 8.0,
		},
		"floor": "res://assets/sprites/floor_grass.png", "rug": "res://assets/sprites/rug_garden.png",
		"frame_tint": Pal.MINT.lightened(0.2),
		"speed": 195.0, "accel": 1600.0, "friction": 2200.0,
		"boot_scale": 0.8, "offset": 20.0,
		"pickups": {
			"sheet": "res://assets/sprites/pickups_backyard.png",
			"names": ["BERRY", "APPLE", "GOLDEN ACORN"],
			"colors": [Pal.PERI, Pal.ROSE, Pal.BUTTER],
			"stat": "BERRIES EATEN", "interval": 0.9, "max": 8,
		},
		"decor": {"sheet": "res://assets/sprites/decor_backyard.png", "frames": 6, "count": 15, "max_each": 3},
	},
	{
		"id": "garage", "name": "GARAGE", "tagline": "heavy duty. no mercy.",
		"intro": "WHO LEFT THE GARAGE DOOR OPEN?",
		"frame": "res://assets/sprites/frame.png",
		"footwear": {"name": "BOOT", "sheet": "res://assets/sprites/boot.png", "sound": "stomp", "shake": 0.55, "dust": Pal.PEACH},
		"chaser": {
			"name": "HENRY", "sheet": "res://assets/sprites/henry.png", "color": Pal.ORCHID,
			"speed": 115.0, "turn": 240.0, "lifetime": 16.0, "radius": 44.0,
			"sound": "henry", "gap": 1.5, "rotates": false, "anim": 5.0,
		},
		"floor": "res://assets/sprites/floor_garage.png", "rug": "res://assets/sprites/rug_garage.png",
		"frame_tint": Pal.FOG,
		"speed": 180.0, "accel": 1500.0, "friction": 2000.0,
		"boot_scale": 0.8, "offset": 45.0,
		"pickups": {
			"sheet": "res://assets/sprites/pickups_garage.png",
			"names": ["BOLT", "BATTERY", "GOLDEN GEAR"],
			"colors": [Pal.FOG, Pal.MINT, Pal.BUTTER],
			"stat": "BOLTS COLLECTED", "interval": 1.4, "max": 4,
		},
		"decor": {"sheet": "res://assets/sprites/decor_garage.png", "frames": 6, "count": 11, "max_each": 2},
	},
]
var best_time := 0.0

var _combo_timer := 0.0
var _passive := 0.0
var _changing := false
var _fade: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_save()
	var layer := FADE_SCENE.instantiate()
	add_child(layer)
	_fade = layer.get_node("Fade")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F11:
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _process(delta: float) -> void:
	if not running or get_tree().paused:
		return
	run_time += delta
	_passive += delta * 4.0
	if _passive >= 1.0:
		var whole := int(_passive)
		_passive -= whole
		score += whole
		score_changed.emit(score)
	if combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(0, 1)


func start_run() -> void:
	score = 0
	lives = MAX_LIVES
	combo = 0
	run_time = 0.0
	crumbs_eaten = 0
	near_misses = 0
	best_combo = 0
	new_record = false
	_combo_timer = 0.0
	_passive = 0.0
	running = true
	Engine.time_scale = 1.0
	run_started.emit()
	score_changed.emit(score)
	lives_changed.emit(lives)
	combo_changed.emit(0, 1)


func multiplier() -> int:
	return mini(1 + floori(combo / 4.0), 5)


func combo_ratio() -> float:
	return clampf(_combo_timer / COMBO_WINDOW, 0.0, 1.0)


func add_score(base: int) -> int:
	var gained := base * multiplier()
	score += gained
	score_changed.emit(score)
	return gained


func register_combo(amount := 1) -> void:
	var before := multiplier()
	combo += amount
	best_combo = maxi(best_combo, combo)
	_combo_timer = COMBO_WINDOW
	combo_changed.emit(combo, multiplier())
	if multiplier() > before:
		Audio.play("combo")


func near_miss(pos: Vector2) -> void:
	near_misses += 1
	register_combo()
	var gained := add_score(15)
	popup("CLOSE CALL +%d" % gained, pos + Vector2(0, -56), Pal.BUTTER)
	Audio.play("near_miss")


func lose_life() -> void:
	lives -= 1
	combo = 0
	combo_changed.emit(0, 1)
	lives_changed.emit(lives)
	if lives <= 0:
		end_run()


func heal() -> bool:
	if lives >= MAX_LIVES:
		return false
	lives += 1
	lives_changed.emit(lives)
	return true


func end_run() -> void:
	if not running:
		return
	running = false
	var id: String = worlds[world_index]["id"]
	new_record = score > best_for(world_index)
	best_scores[id] = maxi(best_for(world_index), score)
	best_time = maxf(best_time, run_time)
	_save()
	run_ended.emit()


func world() -> Dictionary:
	return worlds[world_index]


func best_for(index: int) -> int:
	return int(best_scores.get(worlds[index]["id"], 0))


func rank_for(value: int) -> String:
	var result: String = RANKS[0][1]
	for r in RANKS:
		if value >= r[0]:
			result = r[1]
	return result


# --- tiny helpers so gameplay code stays one-liners -------------------------

func popup(text: String, pos: Vector2, color := Color.WHITE) -> void:
	popup_requested.emit(text, pos, color)


func burst(pos: Vector2, color := Color.WHITE, amount := 12) -> void:
	burst_requested.emit(pos, color, amount)


func banner(text: String) -> void:
	banner_requested.emit(text)


func hitstop(duration := 0.06) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func change_scene(path: String) -> void:
	if _changing:
		return
	_changing = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, 0.22)
	await out.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, 0.25)
	await back.finished
	_changing = false


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for w in worlds:
			best_scores[w["id"]] = int(cfg.get_value("records", "best_" + w["id"], 0))
		if best_scores["kitchen"] == 0:
			best_scores["kitchen"] = int(cfg.get_value("records", "best_score", 0))
		best_time = float(cfg.get_value("records", "best_time", 0.0))


func _save() -> void:
	var cfg := ConfigFile.new()
	for i in worlds.size():
		cfg.set_value("records", "best_" + worlds[i]["id"], best_for(i))
	cfg.set_value("records", "best_time", best_time)
	cfg.save(SAVE_PATH)
