extends Node2D
## A rolling pin the size of a tree trunk. Warning column first, then it rolls down the screen.

const START_Y := -60.0
const END_Y := 790.0

@export var warning_time := 1.2
@export var roll_time := 1.5

@onready var lane: TextureRect = $Lane
@onready var pin: Node2D = $Pin
@onready var sprite: Sprite2D = $Pin/Sprite2D
@onready var hit_area: Area2D = $Pin/Hit
@onready var near_area: Area2D = $Pin/Near

var _rolling := false
var _hit := false
var _near_player: Player
var _t := 0.0


func _ready() -> void:
	pin.position.y = START_Y
	lane.modulate.a = 0.0
	Audio.play("warn", 0.6, -6.0)
	await get_tree().create_timer(warning_time, false).timeout
	_roll()


func _process(delta: float) -> void:
	_t += delta
	if not _rolling:
		lane.modulate.a = (0.22 + 0.18 * sin(_t * 16.0)) * minf(1.0, _t * 4.0)
	sprite.frame = int(pin.position.y / 14.0) % 4 if pin.position.y > 0.0 else 0


func _physics_process(_delta: float) -> void:
	if not _rolling:
		return
	for body in hit_area.get_overlapping_bodies():
		var player := body as Player
		if player and player.hurt():
			_hit = true
	for body in near_area.get_overlapping_bodies():
		var player := body as Player
		if player:
			_near_player = player


func _roll() -> void:
	_rolling = true
	Audio.play("swipe", 0.55)
	Game.screen_shake.emit(0.2)
	hit_area.monitoring = true
	near_area.monitoring = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(pin, "position:y", END_Y, roll_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(lane, "modulate:a", 0.0, 0.4)
	await tw.finished
	if _near_player and not _hit and _near_player.alive:
		Game.near_miss(_near_player.global_position)
	queue_free()
