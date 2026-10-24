
extends Node2D

@onready var background: TextureRect = $Floor
@onready var player: CharacterBody2D = get_node_or_null("player")

func _ready() -> void:
	background.position = Vector2.ZERO
	background.size = Vector2(1280, 720)
	background.texture = load("res://assets/sprites/floor.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -1

	if player:
		player.bounds = Rect2(48, 76, 1184, 596)
