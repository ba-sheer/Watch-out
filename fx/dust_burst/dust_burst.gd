extends CPUParticles2D
## One-shot puff of particles (sprite: assets/sprites/fx/puff.png, tinted).
## Spawned by the world when something calls Game.burst().

var tint := Color.WHITE
var count := 12


func _ready() -> void:
	amount = count
	color = tint
	one_shot = true
	explosiveness = 1.0
	emitting = true
	create_tween().tween_property(self, "modulate:a", 0.0, lifetime)
	await get_tree().create_timer(lifetime + 0.3, false).timeout
	queue_free()
