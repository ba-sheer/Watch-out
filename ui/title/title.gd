extends Node2D

const WORLD_PATH := "res://levels/world/World.tscn"
const BOOT_BASE := Vector2(980, 215)

@onready var boot: Sprite2D = $BigBoot
@onready var guy: Sprite2D = $LittleGuy
@onready var warning: Sprite2D = $Warning
@onready var floor_rect: TextureRect = $Floor
@onready var title_label: Label = %TitleLabel
@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var best_label: Label = %BestLabel
@onready var world_label: Label = %WorldLabel
@onready var tagline_label: Label = %TaglineLabel
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton

var _t := 0.0
var _stick_ready := true


func _ready() -> void:
	Audio.play_music()
	Audio.duck_music(false)
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(get_tree().quit)
	prev_button.pressed.connect(_cycle.bind(-1))
	next_button.pressed.connect(_cycle.bind(1))
	play_button.grab_focus()
	if OS.has_feature("web"):
		quit_button.hide()
	_refresh_world()


## _input (not _unhandled_input): the focused PLAY button would otherwise eat the arrow keys
## for focus navigation before we ever saw them.
func _input(event: InputEvent) -> void:
	var step := 0
	var motion := event as InputEventJoypadMotion
	if motion:
		# a held stick spams motion events: only react once per push, re-arm when it returns to centre
		if motion.axis != JOY_AXIS_LEFT_X:
			return
		if absf(motion.axis_value) < 0.5:
			_stick_ready = true
			return
		if not _stick_ready:
			return
		_stick_ready = false
		step = 1 if motion.axis_value > 0.0 else -1
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		step = -1
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		step = 1
	if step != 0:
		get_viewport().set_input_as_handled()
		_cycle(step)


func _process(delta: float) -> void:
	_t += delta
	guy.frame = int(_t * 3.0) % 2
	boot.position = BOOT_BASE + Vector2(0, sin(_t * 1.4) * 16.0)
	var closeness := 0.5 + 0.5 * sin(_t * 1.4 + PI)
	warning.modulate.a = 0.35 + 0.4 * closeness
	var hue := 0.55 + 0.04 * sin(_t * 2.0)
	title_label.add_theme_color_override("font_color", Color.from_hsv(hue, 0.45, 1.0))


func _cycle(step: int) -> void:
	Game.world_index = posmod(Game.world_index + step, Game.worlds.size())
	Audio.play("click")
	_refresh_world()


func _refresh_world() -> void:
	var w: Dictionary = Game.world()
	world_label.text = w["name"]
	tagline_label.text = w["tagline"]
	floor_rect.texture = load(w["floor"])
	var footwear: Dictionary = w["footwear"]
	boot.texture = load(footwear["sheet"])
	var best :int= Game.best_for(Game.world_index)
	best_label.text = "BEST  %d" % best if best > 0 else "no record here yet. go get squished."


func _on_play() -> void:
	Audio.play("click")
	Game.change_scene(WORLD_PATH)
