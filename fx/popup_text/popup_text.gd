extends Label
## Floating text: "+10", "CLOSE CALL", the little guy's screams.

var _tint := Color.WHITE


func setup(message: String, tint := Color.WHITE) -> void:
	text = message
	_tint = tint


func _ready() -> void:
	add_theme_color_override("font_color", _tint)
	reset_size()
	pivot_offset = size / 2.0
	position -= size / 2.0
	scale = Vector2(0.4, 0.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - 46.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.6)
	tw.chain().tween_callback(queue_free)
