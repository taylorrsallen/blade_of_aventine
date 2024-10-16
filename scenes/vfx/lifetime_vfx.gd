class_name LifetimeVFX extends Node3D

@export var lifetime: float = 5.0
var lifetime_timer: float

func _ready() -> void:
	$GPUParticles3D.emitting = true

func _physics_process(delta: float) -> void:
	lifetime_timer += delta
	if lifetime_timer > lifetime: queue_free()
