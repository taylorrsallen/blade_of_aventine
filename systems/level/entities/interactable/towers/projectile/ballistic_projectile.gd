class_name BallisticProjectile extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var direction: Vector3
@export var speed: float
@export var lifetime: float = 10.0
var lifetime_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$DamagingArea3D.dealt_damage.connect(_on_damage_dealt)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime_timer += delta
	if lifetime_timer >= lifetime: queue_free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damage_dealt() -> void:
	$DamagingArea3D.active = false
	queue_free()
