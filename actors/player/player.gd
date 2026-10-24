class_name Player
extends CharacterBody2D
## The little guy. Moves, dashes, gets stepped on.

signal dash_changed(ratio: float)

const FRAME_IDLE := 0
const FRAME_RUN := 2
const FRAME_HURT := 6
const FRAME_DASH := 7
const QUIPS := [
	"I'M JUST A LITTLE GUY!!!",
	"OW!!!",
	"WHY ME?!",
	"I HAVE A FAMILY!!",
	"THAT WAS MY GOOD SCARF",
	"I'M TINY!!!",
]

@export var speed := 190.0
@export var acceleration := 1600.0
@export var friction := 2200.0
@export var dash_speed := 560.0
@export var dash_duration := 0.15
@export var dash_cooldown := 1.0
@export var invulnerable_time := 1.5
@export var bounds := Rect2(48, 76, 1184, 596)

@onready var sprite: Sprite2D = $Sprite2D
@onready var dust: CPUParticles2D = $Dust

var alive := true

var _dash_left := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.RIGHT
var _invuln := 0.0
var _hurt_t := 0.0
var _anim_t := 0.0
var _ghost_t := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	Game.run_ended.connect(_on_run_ended)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * dash_speed
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = 0.03
			_spawn_ghost()
	else:
		if input != Vector2.ZERO:
			velocity = velocity.move_toward(input * speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
			_start_dash(input)

	move_and_slide()
	position = position.clamp(bounds.position, bounds.end)
	dash_changed.emit(1.0 - _dash_cd / dash_cooldown)
	_animate(delta, input)


func is_invulnerable() -> bool:
	return _invuln > 0.0 or _dash_left > 0.0


## Returns true if the hit actually landed.
func hurt() -> bool:
	if not alive or is_invulnerable():
		return false
	_invuln = invulnerable_time
	_hurt_t = 0.35
	Audio.play("hurt")
	Game.burst(global_position, Pal.ROSE, 20)
	Game.screen_shake.emit(0.8)
	Game.popup(QUIPS.pick_random(), global_position + Vector2(0, -62), Pal.WHITE)
	Game.hitstop(0.09)
	Game.lose_life()
	return true


func _start_dash(input: Vector2) -> void:
	_dash_dir = input if input != Vector2.ZERO else Vector2(-1 if sprite.flip_h else 1, 0)
	_dash_dir = _dash_dir.normalized()
	_dash_left = dash_duration
	_dash_cd = dash_cooldown
	Audio.play("dash")
	Game.burst(global_position, Pal.SKY, 6)


func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.hframes = sprite.hframes
	g.frame = sprite.frame
	g.flip_h = sprite.flip_h
	g.scale = sprite.scale
	g.modulate = Color(Pal.SKY, 0.55)
	g.z_index = -1
	get_parent().add_child(g)
	g.global_position = global_position
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


func _animate(delta: float, input: Vector2) -> void:
	_anim_t += delta
	if absf(input.x) > 0.1:
		sprite.flip_h = input.x < 0.0
	var moving := velocity.length() > 25.0
	if _hurt_t > 0.0:
		sprite.frame = FRAME_HURT
	elif _dash_left > 0.0:
		sprite.frame = FRAME_DASH
	elif moving:
		sprite.frame = FRAME_RUN + int(_anim_t * 12.0) % 4
	else:
		sprite.frame = FRAME_IDLE + int(_anim_t * 3.0) % 2
	dust.emitting = moving and _dash_left <= 0.0
	if _invuln > 0.0 and _dash_left <= 0.0:
		sprite.modulate.a = 0.35 if int(_invuln * 16.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


func _on_run_ended() -> void:
	alive = false
	dust.emitting = false
	sprite.frame = FRAME_HURT
	sprite.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(4.0, 1.2), 0.12)
