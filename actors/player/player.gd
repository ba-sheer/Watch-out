
class_name Player
extends CharacterBody2D

@export var speed := 190.0
@export var acceleration := 1600.0
@export var friction := 2200.0
@export var dash_speed := 560.0
@export var dash_duration := 0.15
@export var dash_cooldown := 1.0
@export var bounds := Rect2(48, 76, 1184, 596)

const FRAME_IDLE := 0
const FRAME_RUN := 2
const FRAME_DASH := 7

@onready var sprite: Sprite2D = $Sprite2D
@onready var dust: CPUParticles2D = $Dust

var _dash_left := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.RIGHT
var _anim_t := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)

	_dash_cd = maxf(0.0, _dash_cd - delta)

	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * dash_speed
	else:
		if input != Vector2.ZERO:
			velocity = velocity.move_toward(
				input * speed, acceleration * delta
			)
		else:
			velocity = velocity.move_toward(
				Vector2.ZERO, friction * delta
			)

		if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
			_start_dash(input)

	move_and_slide()
	position = position.clamp(bounds.position, bounds.end)

	_animate(delta, input)

	# Original dust behavior.
	dust.emitting = velocity.length() > 25.0 and _dash_left <= 0.0


func _start_dash(input: Vector2) -> void:
	_dash_dir = (
		input.normalized()
		if input != Vector2.ZERO
		else Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	)

	_dash_left = dash_duration
	_dash_cd = dash_cooldown


func _animate(delta: float, input: Vector2) -> void:
	_anim_t += delta

	if absf(input.x) > 0.1:
		sprite.flip_h = input.x < 0.0

	if _dash_left > 0.0:
		sprite.frame = FRAME_DASH
	elif velocity.length() > 25.0:
		sprite.frame = FRAME_RUN + int(_anim_t * 12.0) % 4
	else:
		sprite.frame = FRAME_IDLE + int(_anim_t * 3.0) % 2
