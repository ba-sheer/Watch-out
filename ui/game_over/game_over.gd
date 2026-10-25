extends Node2D

const WORLD_PATH := "res://levels/world/World.tscn"
const TITLE_PATH := "res://ui/title/title.tscn"

@onready var floor_rect: TextureRect = $Floor
@onready var squished: Sprite2D = $Squished
@onready var boot: Sprite2D = $BigBoot
@onready var score_label: Label = %ScoreLabel
@onready var rank_label: Label = %RankLabel
@onready var record_label: Label = %RecordLabel
@onready var stats: VBoxContainer = %Stats
@onready var retry_button: Button = %RetryButton
@onready var title_button: Button = %TitleButton

var _foot: Dictionary


func _ready() -> void:
	var w: Dictionary = Game.world()
	floor_rect.texture = load(w["floor"])
	_foot = w["footwear"]
	boot.texture = load(_foot["sheet"])
	score_label.text = "%d" % Game.score
	rank_label.text = "RANK:  %s" % Game.rank_for(Game.score)
	record_label.visible = Game.new_record
	var secs := int(Game.run_time)
	var items: Dictionary = w["pickups"]
	_add_stat("WORLD", w["name"])
	_add_stat("SURVIVED", "%d:%02d" % [int(secs / 60), secs % 60])
	_add_stat(items["stat"], str(Game.crumbs_eaten))
	_add_stat("CLOSE CALLS", str(Game.near_misses))
	_add_stat("BEST COMBO", str(Game.best_combo))
	_add_stat("PERSONAL BEST", str(Game.best_for(Game.world_index)))

	retry_button.pressed.connect(func(): _go(WORLD_PATH))
	title_button.pressed.connect(func(): _go(TITLE_PATH))
	retry_button.grab_focus()

	boot.position.y = -200.0
	var drop := create_tween()
	drop.tween_property(boot, "position:y", 360.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_callback(_on_boot_landed)

	var i := 0
	for row in stats.get_children():
		row.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(row, "modulate:a", 1.0, 0.25).set_delay(0.7 + i * 0.22)
		i += 1


func _on_boot_landed() -> void:
	Audio.play(_foot["sound"])
	Game.screen_shake.emit(_foot["shake"] + 0.1)


func _add_stat(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(240, 0)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Pal.FOG)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 22)
	row.add_child(l)
	row.add_child(v)
	stats.add_child(row)


func _go(path: String) -> void:
	Audio.play("click")
	Game.change_scene(path)
