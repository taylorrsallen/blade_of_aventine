class_name TowerBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const FACE_TARGET: PackedScene = preload("res://systems/common/face_target/face_target.scn")

const LEVEL_COLORS: Array[Color] = [
	Color8(157, 157, 157),
	Color8(255, 255, 255),
	Color8(30, 255, 0),
	Color8(0, 112, 221),
	Color8(163, 53, 238),
	Color8(255, 128, 0),
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var range_indicator: MeshInstance3D = $RangeIndicator

var type_data: TowerTypeData: set = _set_type_data

var foundation: ModelWithHeight
var pitch_pivot: FaceTarget
var pitch_pivot_model: TowerPitchPivotModel
var yaw_pivot: FaceTarget
var yaw_pivot_model: TowerYawPivotModel

var level: int
var experience: float

var enemies: Array[Character] = []
var protect_position: bool
var position_to_protect: Vector3

var target: Node3D
var target_aim_point: Vector3

var firing_cd: float = 1.0
var firing: bool
var firing_timer: float

var built: bool
var build_timer: float
var started_building: bool

var start_position: Vector3
var current_animation_position: Vector3

var health: float

var waiting_on_area_query: bool
var area_query_cd: float = 0.2
var area_query_timer: float

var scepter_damage_reset_cd: float = 3.0
var scepter_damage_reset_timer: float
var scepter_damage_to_destruction: float = 3.0
var scepter_damage: float

var readied: bool

func _set_type_data(_type_data: TowerTypeData) -> void:
	type_data = _type_data
	
	if !readied: return
	
	if type_data.foundation_scene:
		if is_instance_valid(foundation): foundation.queue_free()
		foundation = type_data.foundation_scene.instantiate()
		add_child(foundation)
	
	if type_data.yaw_pivot_scene:
		if is_instance_valid(yaw_pivot): yaw_pivot.queue_free()
		yaw_pivot = FACE_TARGET.instantiate()
		yaw_pivot.position.y = foundation.height
		foundation.add_child(yaw_pivot)
		if is_instance_valid(yaw_pivot_model): yaw_pivot_model.queue_free()
		yaw_pivot_model = type_data.yaw_pivot_scene.instantiate()
		yaw_pivot.add_child(yaw_pivot_model)
	
	if type_data.pitch_pivot_scene:
		if is_instance_valid(pitch_pivot): pitch_pivot.queue_free()
		pitch_pivot = FACE_TARGET.instantiate()
		pitch_pivot.position = yaw_pivot_model.pitch_pivot_rotor.position
		pitch_pivot.rotation_degrees.z = 90.0
		yaw_pivot.add_child(pitch_pivot)
		if is_instance_valid(pitch_pivot_model): pitch_pivot_model.queue_free()
		pitch_pivot_model = type_data.pitch_pivot_scene.instantiate()
		pitch_pivot_model.rotation_degrees.z = -90.0
		pitch_pivot.add_child(pitch_pivot_model)
	
	var tower_height: float = foundation.height + yaw_pivot_model.height
	$InteractableCollider/CollisionShape3D.shape.size.y = tower_height
	$InteractableCollider/CollisionShape3D.position.y = tower_height * 0.5
	
	var effective_range: float = type_data.level_blueprints[level].attack_range + Util.main.level.get_placement_height_at_global_coord(global_position)
	$RangeIndicator.mesh.top_radius = effective_range
	$RangeIndicator.mesh.bottom_radius = effective_range
	
	if type_data.interactable_data: interactable_data = type_data.interactable_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$InteractableCollider/CollisionShape3D.shape = $InteractableCollider/CollisionShape3D.shape.duplicate()
	$RangeIndicator.mesh = $RangeIndicator.mesh.duplicate()
	
	just_highlighted.connect(_on_just_highlighted)
	just_unhighlighted.connect(_on_just_unhighlighted)
	
	readied = true
	type_data = type_data
	
	start_position = global_position
	
	global_position.y = -(foundation.height + yaw_pivot_model.height)
	
	position_to_protect = Util.main.level.centered_global_coord_from_local_coord(Util.main.level.faction_base_local_coords[faction_id])
	protect_position = true

func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	_update(delta)
	
	if !is_instance_valid(target): return
	
	if _try_fire():
		target_aim_point = _get_aim_point()
		yaw_pivot.face_point(target_aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
		
		if is_instance_valid(pitch_pivot):
			pitch_pivot.face_point(target_aim_point, delta * type_data.level_blueprints[level].move_speed_multiplier)
			if yaw_pivot.is_facing_point(target_aim_point) && pitch_pivot.is_facing_point(target_aim_point):
				_fire_projectile()
		else:
			if yaw_pivot.is_facing_point(target_aim_point):
				_fire_projectile()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _fire_projectile() -> void:
	firing = false
	if type_data.projectile_sound: SoundManager.play_pitched_3d_sfx(type_data.projectile_sound.id, type_data.projectile_sound.type, global_position, 0.9, 1.1, 0.0, 5.0)
	pitch_pivot_model.projectile_emitter.hide()
	
	var arrow: ProjectileBase = type_data.projectile.instantiate()
	
	arrow.data = type_data.projectile_data
	arrow.data.damage_data.damage_strength *= type_data.level_blueprints[level].damage_multiplier
	arrow.data.speed = type_data.level_blueprints[level].projectile_speed
	
	arrow.position = pitch_pivot_model.projectile_emitter.global_position
	arrow.basis = pitch_pivot_model.projectile_emitter.global_basis
	arrow.direction = -pitch_pivot_model.projectile_emitter.global_basis.z
	arrow.flat_direction = target_aim_point - global_position
	arrow.flat_direction.y = 0.0
	arrow.flat_direction = arrow.flat_direction.normalized()
	arrow.start_distance = Vector3(global_position.x, 0.0, global_position.z).distance_to(Vector3(target_aim_point.x, 0.0, target_aim_point.z))
	arrow.source = self
	Util.main.level.add_child(arrow)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update(delta: float) -> void:
	if health < type_data.level_blueprints[level].max_health:
		health = min(health + delta, type_data.level_blueprints[level].max_health)
	
	_update_target_seeking(delta)
	
	if scepter_damage > 0.0:
		scepter_damage_reset_timer += delta
		if scepter_damage_reset_timer >= scepter_damage_reset_cd:
			scepter_damage_reset_timer = 0.0
			scepter_damage = 0.0

func _update_target_seeking(delta: float) -> void:
	if !type_data.seek_targets: return
	firing_timer = min(firing_cd, firing_timer + delta * type_data.level_blueprints[level].attack_speed_multiplier)
	if !type_data.shoot_while_held && grabbed: return
	_update_enemy_area_query(delta)

func _try_fire() -> bool:
	if !type_data.shoot_while_held && grabbed: return false
	if firing: return true
	if firing_timer >= firing_cd:
		firing_timer = 0.0
		firing = true
		_reload()
		return true
	else:
		return false

func _reload() -> void:
	if type_data.reload_sound:
		SoundManager.play_pitched_3d_sfx(type_data.reload_sound.id, type_data.reload_sound.type, global_position)
	pitch_pivot_model.projectile_emitter.show()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_build_tower(delta: float) -> bool:
	if !started_building:
		started_building = true
		SoundManager.play_pitched_3d_sfx(2, SoundDatabase.SoundType.SFX_FOLEY, global_position)
	
	if !built:
		build_timer += delta
		if build_timer >= type_data.build_time:
			position = start_position
			current_animation_position = start_position
			if type_data.seek_targets: firing_timer = firing_cd
			built = true
			return true
		else:
			var tower_height: float = foundation.height + yaw_pivot_model.height
			var build_percent: float = build_timer / type_data.build_time
			health = type_data.level_blueprints[0].max_health * build_percent
			position.y = -tower_height + tower_height * build_percent + start_position.y
			position.x = start_position.x + randf_range(-0.05, 0.05)
			position.z = start_position.z + randf_range(-0.05, 0.05)
			current_animation_position = position
		
		return false
	return true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func deal_scepter_damage() -> void:
	if destroyed: return
	
	_play_generic_damage_animation()
	_deal_scepter_damage()
	
	scepter_damage += 1.0
	scepter_damage_reset_timer = 0.0
	if scepter_damage >= scepter_damage_to_destruction: destroy()

func damage(damage_data: DamageData, _source: Node) -> void:
	if destroyed: return
	
	_play_generic_damage_animation()
	_deal_scepter_damage()
	
	if type_data.level_blueprints[level].max_health < 0.0: return
	health -= damage_data.damage_strength
	if health <= 0.0: destroy()

func damage_sourceless(damage_data: DamageData) -> void:
	damage(damage_data, null)

func destroy() -> void:
	_destroy()
	
	if recipe:
		var block_pile: BlockPile = BLOCK_PILE.instantiate()
		block_pile.position = position
		block_pile.position.y = Util.main.level.get_placement_height_at_global_coord(block_pile.position)
		Util.main.level.add_tile_entity(block_pile)
		for ingredient in recipe.ingredients:
			block_pile.add_block(ingredient)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_experience(_experience: float) -> void:
	experience += _experience
	if experience >= type_data.exp_needed_for_first_level + type_data.extra_exp_requirement_per_level * level:
		level = min(type_data.level_blueprints.size() - 1, level + 1)
		var effective_range: float = type_data.level_blueprints[level].attack_range + Util.main.level.get_placement_height_at_global_coord(global_position)
		$RangeIndicator.mesh.bottom_radius = effective_range
		$RangeIndicator.mesh.top_radius = effective_range
		experience = 0.0
	
	print("Experience: %s | Level: %s" % [experience, level])

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_enemy_area_query(delta: float) -> void:
	area_query_timer += delta
	if !waiting_on_area_query && area_query_timer >= area_query_cd:
		area_query_timer -= area_query_cd
		var effective_range: float = type_data.level_blueprints[level].attack_range + Util.main.level.get_placement_height_at_global_coord(global_position)
		AreaQueryManager.request_area_query(self, global_position, effective_range, 18)
		#DebugDraw3D.draw_sphere(global_position, type_data.level_blueprints[level].attack_range, Color.RED, delta)

func update_area_query(results: Array[PhysicsBody3D]) -> void:
	enemies = []
	for result in results:
		if !is_instance_valid(result): continue
		if result.team != team: enemies.append(result)
	
	target = get_closest_enemy()

func get_closest_enemy() -> Character:
	var closest_enemy: Character = null
	var closest_distance: float = 9999.0
	
	#DebugDraw3D.draw_line(position_to_protect, position_to_protect + Vector3.UP * 20.0, Color.RED, 0.016)
	
	var enemies_with_bread: Array[Character] = []
	for enemy in enemies:
		if !is_instance_valid(enemy): continue
		if enemy.grabbed_entity: enemies_with_bread.append(enemy)
	
	if enemies_with_bread.is_empty():
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
	else:
		if !protect_position:
			for enemy in enemies:
				var distance: float = global_position.distance_to(enemy.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_enemy = enemy
		else:
			# We want the enemy with bread that is FURTHEST from our base
			closest_distance = -1.0
			for enemy in enemies:
				var distance: float = position_to_protect.distance_to(enemy.global_position)
				if distance > closest_distance:
					closest_distance = distance
					closest_enemy = enemy
	
	return closest_enemy

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _get_aim_point() -> Vector3:
	if !target.has_method("get_velocity"): return target.global_position + Vector3.UP * 0.5
	
	var pti: Vector3 = target.global_position + Vector3.UP * 0.5
	var pbi: Vector3 = pitch_pivot_model.projectile_emitter.global_position
	var d: float = pti.distance_to(pbi)
	var vt: Vector3 = target.get_velocity()
	var st: float = vt.length()
	var sb: float = type_data.level_blueprints[level].projectile_speed
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

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _play_generic_damage_animation() -> void:
	for i in 5:
		position = current_animation_position + (Vector3(randf(), randf(), randf()) - Vector3.ONE * 0.5) * 0.3
		await get_tree().create_timer(0.01).timeout
		position = current_animation_position
		await get_tree().create_timer(0.01).timeout

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_just_highlighted(_interactable: Interactable, _source: Character, _controller: PlayerController) -> void:
	range_indicator.show()
	var effective_range: float = type_data.level_blueprints[level].attack_range + Util.main.level.get_placement_height_at_global_coord(global_position)
	$RangeIndicator.mesh.bottom_radius = effective_range
	$RangeIndicator.mesh.top_radius = effective_range

func _on_just_unhighlighted(_interactable: Interactable, _source: Character, _controller: PlayerController) -> void:
	range_indicator.hide()
