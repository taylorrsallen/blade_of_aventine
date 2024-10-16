class_name AnimatedGhost extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var float_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	float_timer = randf_range(0.0, 100.0)

func _physics_process(delta: float) -> void:
	float_timer += delta
	position.y = sin(float_timer) * 0.1
