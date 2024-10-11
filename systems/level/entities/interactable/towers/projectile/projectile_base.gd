class_name ProjectileBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var start_distance: float
@export var start_position: Vector3

@export var distance: float
@export var direction: Vector3
@export var flat_direction: Vector3

var lifetime_timer: float

var pierce_delay_timer: float = 0.1
var pierce_count: int

var data: ProjectileData: set = _set_data

var source: Node: set = _set_source

var model: Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_source(_source: Node) -> void:
	$DamagingArea3D.source = _source

func _set_data(_data: ProjectileData) -> void:
	data = _data
	$DamagingArea3D.damage_data = data.damage_data
	$DamagingArea3D.damage_on_impact = data.damage_on_impact
	add_child(data.model_scene.instantiate())

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _destroy() -> void:
	$DamagingArea3D.active = false
	queue_free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _deal_aoe() -> void:
	var results: Array[PhysicsBody3D] = AreaQueryManager.query_area(global_position, data.aoe_radius, 4)
	var distance_check_position: Vector3 = Vector3(global_position.x, 0.0, global_position.z)
	DebugDraw3D.draw_sphere(distance_check_position, data.aoe_radius, Color.RED, 0.2)
	for result in results:
		if !is_instance_valid(result): continue
		
		var result_check_position: Vector3 = Vector3(result.global_position.x, 0.0, result.global_position.z)
		var distance_from_impact: float = result_check_position.distance_to(distance_check_position)
		var distance_percent: float
		if distance_from_impact > data.aoe_radius:
			distance_percent = 0.0
		else:
			distance_percent = 1.0 - (distance_from_impact / data.aoe_radius)
		
		var force_amount: float = data.aoe_force * distance_percent
		result.get_parent().move_direction += (result.global_position - global_position) * force_amount
		
		var damage_data: DamageData = data.damage_data.duplicate()
		damage_data.damage_strength *= distance_percent
		result.damage(damage_data, source)
		
		print("Damage %s | DistanceFromImpact: %s | DistancePercent: %s" % [damage_data.damage_strength, distance_from_impact, distance_percent])
