class_name Chaser
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $Hit
@onready var hit_shape: CollisionShape2D = $Hit/CollisionShape2D

var _speed := 105.0
var _turn_accel := 200.0
var _lifetime := 15.0
var _rotates := true      
var _anim_rate := 2.5
var _sound := "roomba"
var _sound_gap := 1.2

var _vel := Vector2.ZERO
var _age := 0.0
var _beep := 0.0
var _exit_dir := Vector2.ZERO
var _leaving := false


func _ready() -> void:
	var c: Dictionary = Game.world()["chaser"]
	_speed = c["speed"]
	_turn_accel = c["turn"]
	_lifetime = c["lifetime"]
	_rotates = c["rotates"]
	_anim_rate = c["anim"]
	_sound = c["sound"]
	_sound_gap = c["gap"]
	sprite.texture = load(c["sheet"])
	sprite.hframes = 2
	
	var circle := CircleShape2D.new()
	circle.radius = c["radius"]
	hit_shape.shape = circle
	Game.popup("%s!" % c["name"], global_position.clamp(Vector2(120, 100), Vector2(1160, 620)), c["color"])


func _process(delta: float) -> void:
	_age += delta
	var desired := Vector2.ZERO
	if _age > _lifetime:
		if not _leaving:
			_leaving = true
			_exit_dir = (global_position - Vector2(640, 360)).normalized()
		desired = _exit_dir
	else:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.alive:
			desired = (player.global_position - global_position).normalized()
	_vel = _vel.move_toward(desired * _speed, _turn_accel * delta)
	position += _vel * delta

	if _rotates:
		if _vel.length() > 5.0:
			sprite.rotation = lerp_angle(sprite.rotation, _vel.angle(), 6.0 * delta)
	else:
		if absf(_vel.x) > 8.0:
			sprite.flip_h = _vel.x < 0.0
		sprite.position.y = -absf(sin(_age * 9.0)) * 3.0
	sprite.frame = int(_age * _anim_rate) % 2

	_beep -= delta
	if _beep <= 0.0:
		_beep = _sound_gap
		Audio.play(_sound, 1.0, -10.0)
	if _leaving and (position.x < -150 or position.x > 1430 or position.y < -150 or position.y > 870):
		queue_free()


func _physics_process(_delta: float) -> void:
	for body in hit_area.get_overlapping_bodies():
		var player := body as Player
		if player:
			player.hurt()
