class_name Tower extends TowerBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var face_target_y: FaceTarget = $Model/FaceTargetY
@onready var face_target_x: FaceTarget = $Model/FaceTargetY/FaceTargetX

@onready var projectile_emitter: Node3D = $Model/FaceTargetY/FaceTargetX/ProjectileEmitter
@onready var loaded_arrow: MeshInstance3D = $Model/FaceTargetY/FaceTargetX/ProjectileEmitter/LoadedArrow

#@export var projectile: ProjectileData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	init()

func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	
	_update(delta)
	
	if !firing:
		firing_timer += delta * type_data.level_blueprints[level].attack_speed_multiplier
		if firing_timer >= firing_cd:
			firing_timer = 0.0
			firing = true
		else:
			return
	
	if !is_instance_valid(target): return
	
	var aim_point: Vector3 = target.global_position + Vector3.UP
	face_target_y.face_point(aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
	face_target_x.face_point(aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
	
	if face_target_y.is_facing_point(aim_point) && face_target_x.is_facing_point(aim_point):
		fire_projectile()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func fire_projectile() -> void:
	firing = false
	
	var arrow: ProjectileBase = type_data.projectile.instantiate()
	arrow.position = projectile_emitter.global_position
	arrow.basis = projectile_emitter.global_basis
	arrow.direction = -projectile_emitter.global_basis.z
	arrow.damage_data = type_data.base_damage_data.duplicate()
	arrow.damage_data.damage_strength *= type_data.level_blueprints[level].damage_multiplier
	arrow.speed = type_data.level_blueprints[level].projectile_speed
	arrow.source = self
	Util.main.level.add_child(arrow)
	
	#var missile: ProjectileMissile = PROJECTILE_MISSILE_SCN.instantiate()
	#missile.position = projectile_emitter.global_position
	#missile.basis = projectile_emitter.global_basis
	#missile.damage = 2.0
	#missile.init(target, 8.0, 100.0)
	#Util.main_scene.add_child(missile)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _get_aim_point() -> Vector3:
	if !target.has_method("get_velocity"): return target.global_position
	
	var pti: Vector3 = target.global_position
	var pbi: Vector3 = projectile_emitter.global_position
	var d: float = pti.distance_to(pbi)
	var vt: Vector3 = target.get_velocity()
	var st: float = vt.length()
	var sb: float = 1.0 # bullet_speed
	var cos_theta: float = pti.direction_to(pbi).dot(vt.normalized())
	
	var q_root: float = sqrt(2.0 * d * st * cos_theta + 4.0 * (sb * sb - st * st) * d * d)
	var q_sub: float = 2.0 * (sb * sb - st * st)
	var q_left: float = -2.0 * d * st * cos_theta
	var t1: float = (q_left + q_root) / q_sub
	var t2: float = (q_left - q_root) / q_sub
	
	var t: float = min(t1, t2)
	if t < 0.0: t = max(t1, t2)
	if t < 0.0: return Vector3.INF
	return vt * t + pti
