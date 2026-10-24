extends Camera2D

@export var max_offset := Vector2(22, 16)
@export var decay := 1.8

var trauma := 0.0


func _ready() -> void:
	Game.screen_shake.connect(add_trauma)


func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func _process(delta: float) -> void:
	trauma = maxf(0.0, trauma - decay * delta)
	var power := trauma * trauma
	offset = Vector2(randf_range(-1.0, 1.0) * max_offset.x, randf_range(-1.0, 1.0) * max_offset.y) * power
