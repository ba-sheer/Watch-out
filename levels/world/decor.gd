extends Node2D

const PLAYER_START := Vector2(640, 380)
const KEEP_CLEAR := 130.0  
const MIN_GAP := 88.0      
const TRIES := 40           

@export var area := Rect2(70, 90, 1140, 560)


func _ready() -> void:
	var cfg: Dictionary = Game.world()["decor"]
	var sheet: Texture2D = load(cfg["sheet"])
	var frames: int = cfg["frames"]
	var count: int = cfg["count"]
	var max_each: int = cfg["max_each"]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var used: Array[int] = []
	used.resize(frames)
	used.fill(0)
	var placed: Array[Vector2] = []

	for i in count:
		var options: Array[int] = []
		for f in frames:
			if used[f] < max_each:
				options.append(f)
		if options.is_empty():
			break

		var spot := Vector2.ZERO
		var found := false
		for attempt in TRIES:
			var p := Vector2(
				rng.randf_range(area.position.x, area.end.x),
				rng.randf_range(area.position.y, area.end.y))
			if p.distance_to(PLAYER_START) < KEEP_CLEAR:
				continue
			if _crowded(p, placed):
				continue
			spot = p
			found = true
			break
		if not found:
			continue

		var frame: int = options[rng.randi() % options.size()]
		used[frame] += 1
		placed.append(spot)

		var s := Sprite2D.new()
		s.texture = sheet
		s.hframes = frames
		s.frame = frame
		s.scale = Vector2(3, 3)
		s.rotation = rng.randf_range(0.0, TAU)
		s.position = spot
		s.modulate = Color(1, 1, 1, 0.92)
		add_child(s)


func _crowded(p: Vector2, placed: Array[Vector2]) -> bool:
	for q in placed:
		if p.distance_to(q) < MIN_GAP:
			return true
	return false
