class_name Tower extends TowerBase

const BALLISTIC_PROJECTILE = preload("res://systems/level/entities/interactable/towers/projectile/ballistic_projectile.scn")

# ////////////////////////////////////////////////////////////////////////////////////////////////
@onready var face_target_y: FaceTarget = $Model/FaceTargetY
@onready var face_target_x: FaceTarget = $Model/FaceTargetY/FaceTargetX

@onready var projectile_emitter: Node3D = $Model/FaceTargetY/FaceTargetX/ProjectileEmitter
@onready var loaded_arrow: MeshInstance3D = $Model/FaceTargetY/FaceTargetX/ProjectileEmitter/LoadedArrow

#@export var projectile: ProjectileData

# ////////////////////////////////////////////////////////////////////////////////////////////////
func _ready() -> void:
	init()

func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	
	AreaQueryManager.request_area_query(self, global_position, range, 2)
	if !is_instance_valid(target): return
	
	if !firing:
		firing_timer += delta
		if firing_timer >= firing_cd:
			firing_timer = 0.0
			firing = true
		else:
			return
	
	var aim_point: Vector3 = target.global_position + Vector3.UP
	face_target_y.face_point(aim_point, delta)
	face_target_x.face_point(aim_point, delta)
	
	if face_target_y.is_facing_point(aim_point) && face_target_x.is_facing_point(aim_point):
		if burst_count == burst_size:
			burst_count = 0
			firing = false
		if firing:
			burst_timer += delta
			if burst_timer >= burst_cd:
				burst_timer -= burst_cd
				burst_count += 1
				fire_projectile()

# ////////////////////////////////////////////////////////////////////////////////////////////////
func update_area_query(results: Array[PhysicsBody3D]) -> void:
	enemies = []
	for result in results:
		if !is_instance_valid(result): continue
		if result.team != team: enemies.append(result)
	
	target = get_closest_enemy()

func get_closest_enemy() -> Character:
	var closest_enemy: Character = null
	var closest_distance: float = 9999.0
	
	DebugDraw3D.draw_line(position_to_protect, position_to_protect + Vector3.UP * 20.0, Color.RED, 0.016)
	
	if !protect_position:
		for enemy in enemies:
			if !is_instance_valid(enemy): continue
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	else:
		for enemy in enemies:
			if !is_instance_valid(enemy): continue
			var distance: float = position_to_protect.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	return closest_enemy

# ////////////////////////////////////////////////////////////////////////////////////////////////
func fire_projectile() -> void:
	var arrow: BallisticProjectile = BALLISTIC_PROJECTILE.instantiate()
	arrow.position = projectile_emitter.global_position
	arrow.basis = projectile_emitter.global_basis
	arrow.direction = -projectile_emitter.global_basis.z
	#arrow.damage = 2.0
	arrow.speed = 10.0
	Util.main.level.add_child(arrow)
	
	#var missile: ProjectileMissile = PROJECTILE_MISSILE_SCN.instantiate()
	#missile.position = projectile_emitter.global_position
	#missile.basis = projectile_emitter.global_basis
	#missile.damage = 2.0
	#missile.init(target, 8.0, 100.0)
	#Util.main_scene.add_child(missile)

# ////////////////////////////////////////////////////////////////////////////////////////////////
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
