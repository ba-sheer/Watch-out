class_name Player
extends CharacterBody2D

@export var speed := 190.0
@export var acceleration := 1600.0
@export var friction := 2200.0
@export var bounds := Rect2(48, 76, 1184, 596)

const FRAME_IDLE := 0
const FRAME_RUN := 2

@onready var sprite: Sprite2D = $Sprite2D

var _anim_t := 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input != Vector2.ZERO:
		velocity = velocity.move_toward(
			input * speed,
			acceleration * delta
		)
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			friction * delta
		)

	move_and_slide()
	position = position.clamp(bounds.position, bounds.end)

	_animate(delta, input)


func _animate(delta: float, input: Vector2) -> void:
	_anim_t += delta

	if absf(input.x) > 0.1:
		sprite.flip_h = input.x < 0.0

	if velocity.length() > 25.0:
		sprite.frame = FRAME_RUN + int(_anim_t * 12.0) % 4
	else:
		sprite.frame = FRAME_IDLE + int(_anim_t * 3.0) % 2
