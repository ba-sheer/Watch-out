extends Node2D

const OFF_LEFT := -170.0
const OFF_RIGHT := 1450.0
const ARM_EXTENT := 900.0
const ARM_TEX_WIDTH := 8.0
const SCREEN_W := 1280.0

@export var from_left := true
@export var warning_time := 1.1
@export var swipe_time := 0.55

@onready var lane: TextureRect = $Lane
@onready var arm: Sprite2D = $Arm
@onready var paw: Node2D = $Paw
@onready var sprite: Sprite2D = $Paw/Sprite2D
@onready var hit_area: Area2D = $Paw/Hit
@onready var near_area: Area2D = $Paw/Near

var _swiping := false
var _hit := false
var _near_player: Player
var _t := 0.0
var _start_x := 0.0


func _ready() -> void:
	_start_x = OFF_LEFT if from_left else OFF_RIGHT
	paw.position.x = _start_x
	sprite.flip_h = not from_left
	lane.modulate.a = 0.0
	Audio.play("warn", 0.75, -6.0)
	await get_tree().create_timer(warning_time, false).timeout
	_swipe()


func _process(delta: float) -> void:
	_t += delta
	if not _swiping:
		var k := clampf(_t / warning_time, 0.0, 1.0)
		var dir := 1.0 if from_left else -1.0
		paw.position.x = _start_x + dir * (70.0 * k + 6.0 * sin(_t * 30.0))
		lane.modulate.a = (0.25 + 0.2 * sin(_t * 18.0)) * minf(1.0, _t * 4.0)
	if from_left:
		arm.position.x = -ARM_EXTENT
		arm.scale.x = (paw.position.x + ARM_EXTENT) / ARM_TEX_WIDTH
	else:
		arm.position.x = paw.position.x
		arm.scale.x = (SCREEN_W + ARM_EXTENT - paw.position.x) / ARM_TEX_WIDTH


func _physics_process(_delta: float) -> void:
	if not _swiping:
		return
	for body in hit_area.get_overlapping_bodies():
		var player := body as Player
		if player:
			_hit = true
			player.hurt()
	for body in near_area.get_overlapping_bodies():
		var player := body as Player
		if player:
			_near_player = player


func _swipe() -> void:
	_swiping = true
	Audio.play("swipe", randf_range(0.9, 1.1))
	Game.screen_shake.emit(0.15)
	hit_area.monitoring = true
	near_area.monitoring = true
	var end_x := OFF_RIGHT if from_left else OFF_LEFT
	var tw := create_tween().set_parallel(true)
	tw.tween_property(paw, "position:x", end_x, swipe_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(lane, "modulate:a", 0.0, swipe_time)
	await tw.finished
	if _near_player and not _hit and _near_player.alive:
		Game.near_miss(_near_player.global_position)
	queue_free()
