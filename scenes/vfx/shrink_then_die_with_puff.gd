class_name ShrinkThenDieWithPuff extends LifetimeVFX

const SMOKE_PUFF: PackedScene = preload("res://scenes/vfx/smoke_puff.scn")

func _ready() -> void:
	lifetime = 0.15

func _physics_process(delta: float) -> void:
	lifetime_timer += delta
	scale = Vector3.ONE * (1.0 - (lifetime_timer / lifetime))
	if lifetime_timer >= lifetime:
		var smoke_puff: LifetimeVFX = SMOKE_PUFF.instantiate()
		smoke_puff.position = global_position
		Util.main.add_child(smoke_puff)
		queue_free()
