class_name Hud
extends CanvasLayer

const HEART_FULL := preload("res://assets/sprites/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/sprites/ui/heart_empty.png")

@onready var hearts: HBoxContainer = %Hearts
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var time_label: Label = %TimeLabel
@onready var dash_bar: TextureProgressBar = %DashBar
@onready var banner: Label = %Banner
@onready var flash: TextureRect = %HurtFlash

var _banner_tween: Tween
var _heart_rects: Array[TextureRect] = []
var _last_lives :int = Game.MAX_LIVES


func _ready() -> void:
	for i in Game.MAX_LIVES:
		var r := TextureRect.new()
		r.texture = HEART_FULL
		r.custom_minimum_size = Vector2(48, 48)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts.add_child(r)
		_heart_rects.append(r)
	banner.modulate.a = 0.0
	combo_label.visible = false
	Game.lives_changed.connect(_on_lives_changed)
	Game.score_changed.connect(_on_score_changed)
	Game.combo_changed.connect(_on_combo_changed)
	Game.banner_requested.connect(show_banner)


func _process(delta: float) -> void:
	var secs := int(Game.run_time)
	time_label.text = "%d:%02d" % [floori(float(secs) / 60.0), secs % 60]
	if Game.running and Game.lives == 1:
		flash.modulate.a = maxf(flash.modulate.a, 0.3 + 0.15 * sin(Time.get_ticks_msec() / 150.0))
	elif flash.modulate.a > 0.0 and not get_tree().paused:
		flash.modulate.a = maxf(0.0, flash.modulate.a - delta * 0.6)
	if combo_label.visible:
		combo_label.modulate.a = 0.45 + 0.55 * Game.combo_ratio()


func set_dash(ratio: float) -> void:
	dash_bar.value = ratio
	dash_bar.modulate = Color(1, 1, 1) if ratio >= 1.0 else Pal.FOG.darkened(0.25)


func show_banner(text: String) -> void:
	banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(2.0)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.6)


func _on_lives_changed(lives: int) -> void:
	var lost := lives < _last_lives
	var gained := lives > _last_lives
	if lost:
		flash.modulate.a = 0.85
		create_tween().tween_property(flash, "modulate:a", 0.0, 0.45)
	_last_lives = lives
	for i in _heart_rects.size():
		_heart_rects[i].texture = HEART_FULL if i < lives else HEART_EMPTY
	# pulse the heart that just changed: the empty slot after a hit, the refilled one after a heal
	if lost or gained:
		var idx := lives - 1 if gained else lives
		if idx >= 0 and idx < _heart_rects.size():
			var r := _heart_rects[idx]
			r.pivot_offset = r.size / 2.0
			var tw := create_tween()
			tw.tween_property(r, "scale", Vector2(1.5, 1.5), 0.08)
			tw.tween_property(r, "scale", Vector2.ONE, 0.15)


func _on_score_changed(score: int) -> void:
	score_label.text = "%d" % score


func _on_combo_changed(combo: int, multiplier: int) -> void:
	combo_label.visible = combo > 1
	combo_label.text = "COMBO %d   x%d" % [combo, multiplier]
