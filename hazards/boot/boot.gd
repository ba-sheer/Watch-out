extends Node2D

const FALL_TIME := 0.18

@export var warning_time := 1.1
@export var linger_time := 0.5

@onready var warning: Sprite2D = $Warning
@onready var foot: Sprite2D = $Foot
@onready var hitbox: Area2D = $Hitbox
@onready var near_zone: Area2D = $NearZone

var _sound := "stomp"
var _shake := 0.55
var _dust := Color.WHITE


func _ready() -> void:
	var f: Dictionary = Game.world()["footwear"]
	foot.texture = load(f["sheet"])
	_sound = f["sound"]
	_shake = f["shake"]
	_dust = f["dust"]
	foot.rotation = randf_range(-0.5, 0.5)
	warning.modulate.a = 0.0
	warning.scale = Vector2(2.2, 2.2)
	Audio.play("warn", randf_range(0.95, 1.1), -8.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(warning, "modulate:a", 0.85, warning_time)
	tw.tween_property(warning, "scale", Vector2(3, 3), warning_time).set_trans(Tween.TRANS_SINE)

	await get_tree().create_timer(maxf(0.05, warning_time - FALL_TIME), false).timeout
	_fall()


func _fall() -> void:
	foot.visible = true
	foot.scale = Vector2(4.4, 4.4)
	foot.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(foot, "scale", Vector2(3, 3), FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(foot, "modulate:a", 1.0, FALL_TIME)
	await tw.finished
	_impact()


func _impact() -> void:
	Audio.play(_sound, randf_range(0.9, 1.1))
	Game.screen_shake.emit(_shake)
	Game.burst(global_position, _dust, 18)
	warning.visible = false

	var squash := create_tween()
	squash.tween_property(foot, "scale", Vector2(3.25, 2.75), 0.05)
	squash.tween_property(foot, "scale", Vector2(3, 3), 0.12)

	hitbox.monitoring = true
	near_zone.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame

	var landed := false
	for body in hitbox.get_overlapping_bodies():
		var player := body as Player
		if player and player.hurt():
			landed = true
	if not landed:
		for body in near_zone.get_overlapping_bodies():
			var player := body as Player
			if player and player.alive and not player.is_invulnerable():
				Game.near_miss(player.global_position)
	hitbox.monitoring = false
	near_zone.monitoring = false

	await get_tree().create_timer(linger_time, false).timeout
	var fade := create_tween()
	fade.tween_property(foot, "modulate:a", 0.0, 0.3)
	await fade.finished
	queue_free()
