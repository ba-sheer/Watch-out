class_name Director
extends Node

const BOOT_SCENE := preload("res://hazards/boot/Boot.tscn")
const PAW_SCENE := preload("res://hazards/cat_paw/cat_paw.tscn")
const PIN_SCENE := preload("res://hazards/rolling_pin/rolling_pin.tscn")
const CHASER_SCENE := preload("res://actors/chaser/chaser.tscn")
const PICKUP_SCENE := preload("res://pickups/pickup.tscn")


const EVENTS := [
	{"t": 18.0, "text": "A CAT HAS NOTICED YOU"},
	{"t": 36.0, "text": "{roller}"},
	{"t": 60.0, "text": "{chaser} O'CLOCK"},
	{"t": 90.0, "text": "THE {foot} BRIGADE ARRIVES"},
	{"t": 130.0, "text": "YOU ARE STILL A LITTLE GUY"},
]

var player: Player
var boot_scale := 1.0
var pickup_interval := 1.2
var pickup_max := 6
var offset := 0.0
var hazards: Node2D
var pickups: Node2D

var _boot_cd := 2.0
var _paw_cd := 1.0
var _pin_cd := 1.0
var _chaser_cd := 1.0
var _brigade_cd := 4.0
var _pickup_cd := 0.4
var _next_event := 0
var _intro := ""
var _chaser_name := "ROOMBA"
var _foot_name := "BOOT"
var _roller_line := "SOMEONE LEFT THE ROLLING PIN OUT"
var _intro_shown := false
var _chaser: Node2D


func setup(w: Dictionary) -> void:
	boot_scale = w["boot_scale"]
	offset = w["offset"]
	_intro = w["intro"]
	var chaser: Dictionary = w["chaser"]
	_chaser_name = chaser["name"]
	var footwear: Dictionary = w["footwear"]
	_foot_name = footwear["name"]
	_roller_line = w["roller"]["line"]
	var items: Dictionary = w["pickups"]
	pickup_interval = items["interval"]
	pickup_max = items["max"]
	_next_event = 0
	while _next_event < EVENTS.size() and EVENTS[_next_event]["t"] <= offset:
		_next_event += 1


func _process(delta: float) -> void:
	if not Game.running or not is_instance_valid(player):
		return
	var t :float= Game.run_time + offset

	if not _intro_shown and Game.run_time >= 0.5:
		_intro_shown = true
		Game.banner(_intro)
	while _next_event < EVENTS.size() and t >= EVENTS[_next_event]["t"]:
		var line: String = EVENTS[_next_event]["text"]
		Game.banner(line.replace("{chaser}", _chaser_name).replace("{foot}", _foot_name).replace("{roller}", _roller_line))
		_next_event += 1

	_boot_cd -= delta
	if _boot_cd <= 0.0:
		_boot_cd = lerpf(1.5, 0.55, clampf(t / 150.0, 0.0, 1.0)) * boot_scale
		_spawn_boot(_aim(130.0))
		if t > 45.0 and randf() < 0.3:
			_spawn_boot(_aim(260.0))

	if t > 18.0:
		_paw_cd -= delta
		if _paw_cd <= 0.0:
			_paw_cd = randf_range(6.0, 10.0) - clampf(t / 120.0, 0.0, 1.0) * 3.0
			_spawn_paw()

	if t > 36.0:
		_pin_cd -= delta
		if _pin_cd <= 0.0:
			_pin_cd = randf_range(9.0, 14.0) - clampf(t / 120.0, 0.0, 1.0) * 3.0
			_spawn_pin()

	if t > 60.0 and not is_instance_valid(_chaser):
		_chaser_cd -= delta
		if _chaser_cd <= 0.0:
			_chaser_cd = randf_range(35.0, 50.0)
			_spawn_chaser()

	if t > 90.0:
		_brigade_cd -= delta
		if _brigade_cd <= 0.0:
			_brigade_cd = randf_range(14.0, 20.0)
			_boot_line()

	_pickup_cd -= delta
	if _pickup_cd <= 0.0:
		_pickup_cd = pickup_interval
		if pickups.get_child_count() < pickup_max:
			_spawn_pickup()


func _aim(spread: float) -> Vector2:
	var p := player.position
	if randf() < 0.3:
		p = Vector2(randf_range(120, 1160), randf_range(130, 620))
	else:
		p += Vector2.from_angle(randf() * TAU) * randf_range(0.0, spread)
	return Vector2(clampf(p.x, 100.0, 1180.0), clampf(p.y, 120.0, 620.0))


func _warning_time(t: float) -> float:
	return lerpf(1.1, 0.8, clampf(t / 120.0, 0.0, 1.0))


func _spawn_boot(pos: Vector2, warn := -1.0) -> void:
	var b = BOOT_SCENE.instantiate()
	b.position = pos
	b.warning_time = warn if warn > 0.0 else _warning_time(Game.run_time + offset)
	hazards.add_child(b)


func _spawn_paw() -> void:
	var paw = PAW_SCENE.instantiate()
	var y := player.position.y + randf_range(-60.0, 60.0) if randf() < 0.6 else randf_range(150.0, 600.0)
	paw.position = Vector2(0.0, clampf(y, 140.0, 620.0))
	paw.from_left = randf() < 0.5
	paw.warning_time = _warning_time(Game.run_time + offset) + 0.1
	hazards.add_child(paw)


func _spawn_pin() -> void:
	var pin = PIN_SCENE.instantiate()
	var x := player.position.x + randf_range(-120.0, 120.0) if randf() < 0.6 else randf_range(260.0, 1020.0)
	pin.position = Vector2(clampf(x, 220.0, 1060.0), 0.0)
	pin.warning_time = _warning_time(Game.run_time + offset) + 0.2
	hazards.add_child(pin)


func _spawn_chaser() -> void:
	var edge := randi() % 4
	var pos := Vector2.ZERO
	match edge:
		0: pos = Vector2(-100, randf_range(150, 600))
		1: pos = Vector2(1380, randf_range(150, 600))
		2: pos = Vector2(randf_range(150, 1130), -100)
		_: pos = Vector2(randf_range(150, 1130), 820)
	_chaser = CHASER_SCENE.instantiate() as Node2D
	_chaser.position = pos
	hazards.add_child(_chaser)


func _boot_line() -> void:
	var horizontal := randf() < 0.5
	var reverse := randf() < 0.5
	var count := 7
	for i in count:
		var f := float(i) / float(count - 1)
		if reverse:
			f = 1.0 - f
		var pos: Vector2
		if horizontal:
			pos = Vector2(lerpf(120.0, 1160.0, f), clampf(player.position.y + randf_range(-40.0, 40.0), 120.0, 620.0))
		else:
			pos = Vector2(clampf(player.position.x + randf_range(-40.0, 40.0), 100.0, 1180.0), lerpf(130.0, 610.0, f))
		_spawn_boot(pos, 0.9)
		await get_tree().create_timer(0.18, false).timeout
		if not Game.running:
			return


func _spawn_pickup() -> void:
	var p := PICKUP_SCENE.instantiate() as Pickup
	var roll := randf()
	if roll < 0.08 and Game.lives < Game.MAX_LIVES:
		p.kind = Pickup.Kind.HEAL
	elif roll < 0.2:
		p.kind = Pickup.Kind.GOLDEN
	else:
		p.kind = Pickup.Kind.COMMON
	p.position = _free_spot()
	pickups.add_child(p)


func _free_spot() -> Vector2:
	var spot := Vector2.ZERO
	for i in 12:
		spot = Vector2(randf_range(100.0, 1180.0), randf_range(120.0, 620.0))
		var clear := spot.distance_to(player.position) > 90.0
		if clear:
			for other in pickups.get_children():
				if (other as Node2D).position.distance_to(spot) < 70.0:
					clear = false
					break
		if clear:
			return spot
	return spot
