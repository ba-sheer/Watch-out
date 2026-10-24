
extends Node

signal run_ended
signal screen_shake(amount: float)

var lives: int = 3
var score: int = 0
var run_finished: bool = false


func burst(_position: Vector2, _color: Color, _amount: int = 10) -> void:
	pass


func popup(message: String, _position: Vector2, _color: Color = Color.WHITE) -> void:
	print(message)


func hitstop(_duration: float = 0.09) -> void:
	pass


func lose_life() -> void:
	lives -= 1
	print("Lives remaining: ", lives)

	if lives <= 0:
		end_run()


func end_run() -> void:
	if run_finished:
		return

	run_finished = true
	run_ended.emit()


func reset_run() -> void:
	lives = 3
	score = 0
	run_finished = false
