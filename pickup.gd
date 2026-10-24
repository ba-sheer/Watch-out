class_name Pickup
extends Area2D

enum Kind { COMMON, HEAL, GOLDEN }

const LIFETIME := 9.0
const MAGNET_RANGE := 90.0
const MAGNET_SPEED := 320.0

@export var kind: Kind = Kind.COMMON

@onready var sprite: Sprite2D = $Sprite2D

var _age := 0.0
var _collected := false
var _pop: Tween
var _item_name := ""
var _tint := Color.WHITE


func _ready() -> void:
	var items: Dictionary = Game.world()["pickups"]
	var names: Array = items["names"]
	var colors: Array = items["colors"]
	_item_name = names[kind]
	_tint = colors[kind]
	sprite.texture = load(items["sheet"])
	sprite.frame = kind

	body_entered.connect(_on_body_entered)
	sprite.scale = Vector2.ZERO
	_pop = create_tween()
	_pop.tween_property(sprite, "scale", Vector2(3, 3), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "position:y", -4.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "position:y", 2.0, 0.5).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if _collected:
		return
	_age += delta
	if _age > LIFETIME - 2.0:
		sprite.visible = int(_age * 10.0) % 2 == 0
	if _age >= LIFETIME:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.alive and kind != Kind.HEAL:
		var to_player := player.global_position - global_position
		if to_player.length() < MAGNET_RANGE:
			global_position += to_player.normalized() * MAGNET_SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if _collected or player == null or not player.alive:
		return
	_collected = true
	set_deferred("monitoring", false)
	var pos := global_position + Vector2(0, -34)
	match kind:
		Kind.COMMON:
			Game.crumbs_eaten += 1
			Game.register_combo()
			var gained := Game.add_score(10)
			Game.popup("+%d" % gained, pos, _tint.lightened(0.5))
			Audio.play("pickup", 1.0 + minf(Game.combo, 12) * 0.04)
			Game.burst(global_position, _tint, 6)
		Kind.GOLDEN:
			Game.crumbs_eaten += 1
			Game.register_combo(2)
			var gained := Game.add_score(50)
			Game.popup("%s! +%d" % [_item_name, gained], pos, _tint)
			Audio.play("golden")
			Game.burst(global_position, _tint, 14)
		Kind.HEAL:
			if Game.heal():
				Game.popup("%s! +1 HEART" % _item_name, pos, _tint.lightened(0.3))
				Audio.play("heal")
			else:
				var gained := Game.add_score(25)
				Game.popup("+%d" % gained, pos, _tint.lightened(0.3))
				Audio.play("pickup")
			Game.burst(global_position, _tint, 10)
	if _pop and _pop.is_valid():
		_pop.kill()
	sprite.visible = true
	var out := create_tween().set_parallel(true)
	out.tween_property(sprite, "scale", Vector2(5, 5), 0.12)
	out.tween_property(sprite, "modulate:a", 0.0, 0.12)
	out.chain().tween_callback(queue_free)
