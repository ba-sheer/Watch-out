
extends Node2D

@onready var player = $Player
@onready var effects = $Effects
@onready var hud = $HUD
@onready var director = $Director
@onready var floor_rect = $Floor
@onready var rug = $Rug
@onready var frame_sprite = $Frame


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#79b957"))

	if player.has_signal("dash_changed") and hud.has_method("set_dash"):
		player.dash_changed.connect(hud.set_dash)

	if director:
		director.player = player

		if has_node("Hazards"):
			director.hazards = $Hazards

		if has_node("Pickups"):
			director.pickups = $Pickups


func _on_popup(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.position = pos
	effects.add_child(label)


func _on_burst(pos: Vector2, color: Color, amount: int) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.color = color
	particles.amount = amount
	particles.emitting = true
	effects.add_child(particles)
