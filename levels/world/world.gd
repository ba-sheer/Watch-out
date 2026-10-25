
extends Node2D


@onready var player = $Player
@onready var effects = $Effects
@onready var hud = $HUD
@onready var director = $Director
@onready var floor_rect = $Floor
@onready var rug = $Rug
@onready var frame_sprite = $Frame

const POPUP_SCENE := preload("res://fx/popup_text/popup_text.tscn")
const DUST_SCENE := preload("res://fx/dust_burst/dust_burst.tscn")

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#79b957"))
	
	var world_data: Dictionary = Game.world()

	frame_sprite.texture = load(world_data["frame"])
	frame_sprite.modulate = world_data["frame_tint"]
	floor_rect.texture = load(world_data["floor"])
	rug.texture = load(world_data["rug"])

	Audio.play_music()
	Audio.duck_music(false)
	Game.popup_requested.connect(_on_popup)
	Game.burst_requested.connect(_on_burst)

	if player.has_signal("dash_changed") and hud.has_method("set_dash"):
		player.dash_changed.connect(hud.set_dash)

	if director:
		director.player = player
		director.hazards = $Hazards
		director.pickups = $Pickups
		director.setup(Game.world())
	

	Game.run_ended.connect(_on_run_ended)
	Game.start_run()

func _exit_tree() -> void:
	if Game.popup_requested.is_connected(_on_popup):
		Game.popup_requested.disconnect(_on_popup)

	if Game.burst_requested.is_connected(_on_burst):
		Game.burst_requested.disconnect(_on_burst)

	if Game.run_ended.is_connected(_on_run_ended):
		Game.run_ended.disconnect(_on_run_ended)

func _on_popup(text: String, pos: Vector2, color: Color) -> void:
	var label = POPUP_SCENE.instantiate()
	label.setup(text, color)
	label.position = pos
	effects.add_child(label)

func _on_burst(pos: Vector2, color: Color, amount: int) -> void:
	var dust = DUST_SCENE.instantiate()
	dust.tint = color
	dust.count = amount
	dust.position = pos
	effects.add_child(dust)
func _on_run_ended() -> void:
	Audio.duck_music(true)
	Audio.play("game_over")
	await get_tree().create_timer(1.8, false).timeout
	Game.change_scene("res://ui/game_over/game_over.tscn")
