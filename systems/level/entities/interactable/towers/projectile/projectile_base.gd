class_name ProjectileBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var direction: Vector3
@export var speed: float

@export var die_on_contact: bool = true

@export var lifetime: float = 10.0
var lifetime_timer: float

@export var piercing_hits: int
@export var pierce_delay: float
var pierce_delay_timer: float = 0.1
var pierce_count: int

var damage_data: DamageData: set = _set_damage_data

var source: Node: set = _set_source

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_source(_source: Node) -> void:
	$DamagingArea3D.source = _source

func _set_damage_data(_damage_data: DamageData) -> void:
	damage_data = _damage_data
	$DamagingArea3D.damage_data = damage_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _destroy() -> void:
	$DamagingArea3D.active = false
	queue_free()
