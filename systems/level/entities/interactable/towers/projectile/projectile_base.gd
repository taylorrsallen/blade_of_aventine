class_name ProjectileBase extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var start_distance: float
@export var start_position: Vector3

@export var distance: float
@export var direction: Vector3
@export var flat_direction: Vector3

var damage_multiplier: float

var lifetime_timer: float

var pierce_delay_timer: float = 0.1
var pierce_count: int

var data: ProjectileData: set = _set_data

var source: Node: set = _set_source

var model: Node3D

var previous_position: Vector3
var velocity: Vector3

var readied: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_source(_source: Node) -> void:
	$DamagingArea3D.source = _source

func _set_damage_multiplier(_damage_multiplier: float) -> void:
	damage_multiplier = _damage_multiplier
	$DamagingArea3D.damage_multiplier = damage_multiplier

func _set_data(_data: ProjectileData) -> void:
	data = _data
	if !readied: return
	$DamagingArea3D.damage_data = data.damage_data
	$DamagingArea3D.damage_on_impact = data.damage_on_impact
	add_child(data.model_scene.instantiate())
	$DamagingArea3D/CollisionShape3D.shape = $DamagingArea3D/CollisionShape3D.shape.duplicate()
	$DamagingArea3D/CollisionShape3D.shape.radius = data.hitbox_radius

func _ready() -> void:
	_do_the_thing()

func _do_the_thing() -> void:
	$DamagingArea3D/CollisionShape3D.shape = $DamagingArea3D/CollisionShape3D.shape.duplicate()
	readied = true
	data = data

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
			distance_percent = 1.0
		else:
			distance_percent = distance_from_impact / data.aoe_radius
		
		var distance_damage_multiplier: float = data.aoe_damage_falloff.sample(distance_percent)
		
		#print("DistanceFromImpact: %s | DistanceDamageMult: %s" % [distance_from_impact, distance_damage_multiplier])
		
		
		var force_amount: float = data.aoe_force * distance_damage_multiplier
		result.get_parent().move_direction += (result.global_position - global_position) * force_amount + Vector3.UP * force_amount
		
		var damage_data: DamageData = data.damage_data.duplicate()
		damage_data.damage_strength *= distance_damage_multiplier
		result.damage(damage_data, source)
		
