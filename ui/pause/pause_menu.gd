extends CanvasLayer
## Pause overlay. Keeps processing while the tree is paused.

const TITLE_PATH := "res://ui/title/title.tscn"

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(resume)
	quit_button.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and Game.running:
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			resume()
		else:
			pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and Game.running and not get_tree().paused:
		pause()


func pause() -> void:
	get_tree().paused = true
	visible = true
	Audio.play("click")
	Audio.duck_music(true)
	resume_button.grab_focus()


func resume() -> void:
	get_tree().paused = false
	visible = false
	Audio.play("click")
	Audio.duck_music(false)


func _on_quit() -> void:
	Game.running = false
	Audio.duck_music(false)
	Game.change_scene(TITLE_PATH)
