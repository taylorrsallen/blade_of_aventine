class_name Tower extends TowerBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var face_target_y: FaceTarget = $Model/FaceTargetY
@onready var face_target_x: FaceTarget = $Model/FaceTargetY/FaceTargetX
#@export var projectile: ProjectileData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	_update(delta)
	
	if !is_instance_valid(target): return
	
	if _try_fire(delta):
		target_aim_point = _get_aim_point()
		face_target_y.face_point(target_aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
		face_target_x.face_point(target_aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
		
		if face_target_y.is_facing_point(target_aim_point) && face_target_x.is_facing_point(target_aim_point):
			fire_projectile()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func fire_projectile() -> void:
	_fire_projectile()
	
	var arrow: ProjectileBase = type_data.projectile.instantiate()
	
	arrow.data = type_data.projectile_data
	arrow.data.damage_data.damage_strength *= type_data.level_blueprints[level].damage_multiplier
	arrow.data.speed = type_data.level_blueprints[level].projectile_speed
	
	arrow.position = projectile_emitter.global_position
	arrow.basis = projectile_emitter.global_basis
	arrow.direction = -projectile_emitter.global_basis.z
	arrow.flat_direction = target_aim_point - global_position
	arrow.flat_direction.y = 0.0
	arrow.flat_direction = arrow.flat_direction.normalized()
	arrow.start_distance = Vector3(global_position.x, 0.0, global_position.z).distance_to(Vector3(target_aim_point.x, 0.0, target_aim_point.z))
	arrow.source = self
	Util.main.level.add_child(arrow)
