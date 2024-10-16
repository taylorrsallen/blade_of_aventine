class_name TowerBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const FACE_TARGET: PackedScene = preload("res://systems/common/face_target/face_target.scn")
var PICKUP: PackedScene = load("res://systems/level/entities/pickup/pickup.scn")

const LEVEL_FLAG_COLORS: Array[Color] = [
	Color8(255, 255, 255),
	Color8(75, 181, 70),
	Color8(58, 129, 199),
	Color8(183, 64, 48),
	Color8(255, 190, 0)
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var range_indicator: MeshInstance3D = $RangeIndicator
@onready var tower_level_pole: TowerLevelPole = $TowerLevelPole

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

var targeting_preference: TowerTypeData.TargetingPreference

var money_fed: int

@onready var build_smoke: Node3D = $BuildSmoke

func _set_type_data(_type_data: TowerTypeData) -> void:
	type_data = _type_data
	
	if !readied: return
	
	targeting_preference = type_data.targeting_preference
	
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
	tower_level_pole.flag_color = LEVEL_FLAG_COLORS[0]
	$InteractableCollider/CollisionShape3D.shape = $InteractableCollider/CollisionShape3D.shape.duplicate()
	$RangeIndicator.mesh = $RangeIndicator.mesh.duplicate()
	
	just_highlighted.connect(_on_just_highlighted)
	just_unhighlighted.connect(_on_just_unhighlighted)
	
	readied = true
	type_data = type_data
	
	build_smoke.global_position = global_position
	start_position = global_position
	
	global_position.y = -(foundation.height + yaw_pivot_model.height)
	
	position_to_protect = Util.main.level.centered_global_coord_from_local_coord(Util.main.level.faction_base_local_coords[faction_id])

func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	_update(delta)
	
	
	if _try_fire():
		if !is_instance_valid(target): return
		
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
	pitch_pivot_model.fire()
	firing = false
	if type_data.fire_sound: SoundManager.play_pitched_3d_sfx(type_data.fire_sound.id, type_data.fire_sound.type, global_position, 0.9, 1.1, 0.0, 5.0)
	pitch_pivot_model.projectile_emitter.hide()
	
	var arrow: ProjectileBase = type_data.projectile.instantiate()
	
	var arrow_data: ProjectileData = type_data.projectile_data.duplicate()
	arrow_data.damage_data = type_data.projectile_data.damage_data.duplicate()
	arrow_data.damage_data.damage_strength *= type_data.level_blueprints[level].damage_multiplier
	arrow.data = arrow_data
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
	if is_instance_valid(target): DebugDraw3D.draw_sphere(target.global_position, 0.5, Color.RED, delta)
	
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
	if !firing:
		firing_timer = min(firing_cd, firing_timer + delta * type_data.level_blueprints[level].attack_speed_multiplier)
		pitch_pivot_model.reload_percent = firing_timer / firing_cd
	else:
		pitch_pivot_model.reload_percent = 1.0
	if !type_data.shoot_while_held && grabbed: return
	_update_enemy_area_query(delta)

func _try_fire() -> bool:
	if !type_data.shoot_while_held && grabbed: return false
	if firing: return true
	if firing_timer >= firing_cd:
		_reload()
		firing_timer = 0.0
		firing = true
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
			build_smoke.queue_free()
			const LARGER_SMOKE_PUFF = preload("res://scenes/vfx/larger_smoke_puff.scn")
			var finished_puff: LifetimeVFX = LARGER_SMOKE_PUFF.instantiate()
			finished_puff.position = global_position - Vector3.UP * 0.5
			Util.main.add_child(finished_puff)
			
			position = start_position
			current_animation_position = start_position
			if type_data.seek_targets: firing_timer = firing_cd
			Util.main.level.place_interactable_at_global_coord(global_position, self)
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
	
	var source_position: Vector3 = global_position
	var coins_to_spawn: Array[PickupData] = CoinSpawner.get_coins_for_amount(money_fed * 0.5)
	for coin in coins_to_spawn:
		var pickup: Pickup = PICKUP.instantiate()
		pickup.pickup_data = coin
		pickup.position = source_position
		Util.main.level.add_pickup(pickup)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_experience(_experience: float) -> void:
	experience += _experience
	if experience >= type_data.exp_needed_for_first_level + type_data.extra_exp_requirement_per_level * level:
		level = min(type_data.level_blueprints.size() - 1, level + 1)
		var effective_range: float = type_data.level_blueprints[level].attack_range + Util.main.level.get_placement_height_at_global_coord(global_position)
		$RangeIndicator.mesh.bottom_radius = effective_range
		$RangeIndicator.mesh.top_radius = effective_range
		experience = 0.0
	
	if level + 1 == type_data.level_blueprints.size():
		tower_level_pole.experience_percent = 1.0
		tower_level_pole.experience_color = Color8(255, 190, 0)
	else:
		tower_level_pole.experience_percent = experience / (type_data.exp_needed_for_first_level + type_data.extra_exp_requirement_per_level * level)
		tower_level_pole.experience_color = Color.GREEN
	tower_level_pole.flag_color = LEVEL_FLAG_COLORS[level]
	#print("Experience: %s | Level: %s" % [experience, level])

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
		if !is_instance_valid(result) || result.team == team: continue
		if type_data.targeting_type == TowerTypeData.TargetingType.ALL:
			enemies.append(result)
		elif type_data.targeting_type == TowerTypeData.TargetingType.GROUND_ONLY && result.body_data.body_type == CharacterBodyData.BodyType.GROUND:
			enemies.append(result)
		elif type_data.targeting_type == TowerTypeData.TargetingType.FLYING_ONLY && result.body_data.body_type == CharacterBodyData.BodyType.FLYING:
			enemies.append(result)
	
	target = get_best_target()

func get_best_target() -> Character:
	var enemies_with_bread: Array[Character] = []
	for enemy in enemies:
		if !is_instance_valid(enemy): continue
		if enemy.grabbed_entity: enemies_with_bread.append(enemy)
	
	if enemies_with_bread.is_empty(): return _get_best_target_from_array(enemies)
	return _get_best_target_from_array(enemies_with_bread)

func _get_best_target_from_array(search_array: Array[Character]) -> Character:
	match targeting_preference:
		TowerTypeData.TargetingPreference.HIGHEST_HP: return _get_highest_hp_target_from_array(search_array)
		TowerTypeData.TargetingPreference.LOWEST_HP: return _get_lowest_hp_target_from_array(search_array)
		TowerTypeData.TargetingPreference.HIGHEST_ARMOR: return _get_highest_armor_target_from_array(search_array)
		TowerTypeData.TargetingPreference.LOWEST_ARMOR: return _get_lowest_armor_target_from_array(search_array)
		TowerTypeData.TargetingPreference.FASTEST: return _get_highest_speed_target_from_array(search_array)
		TowerTypeData.TargetingPreference.SLOWEST: return _get_lowest_speed_target_from_array(search_array)
		TowerTypeData.TargetingPreference.RANDOM: return _get_random_target_from_array(search_array)
		TowerTypeData.TargetingPreference.FURTHEST: return _get_furthest_target_from_array(search_array)
		_: return _get_closest_target_from_array(search_array)

func _get_highest_hp_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var highest_hp: float = 0.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.health > highest_hp:
			best_target = potential_target
			highest_hp = potential_target.health
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.health == highest_hp:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				highest_hp = potential_target.health
				closest_distance = distance
	
	return best_target

func _get_lowest_hp_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var lowest_hp: float = 10000.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.health < lowest_hp:
			best_target = potential_target
			lowest_hp = potential_target.health
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.health == lowest_hp:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				lowest_hp = potential_target.health
				closest_distance = distance
	
	return best_target

func _get_highest_armor_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var highest_armor: float = 0.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.body_data.flat_armor > highest_armor:
			best_target = potential_target
			highest_armor = potential_target.body_data.flat_armor
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.body_data.flat_armor == highest_armor:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				highest_armor = potential_target.body_data.flat_armor
				closest_distance = distance
	
	return best_target

func _get_lowest_armor_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var lowest_armor: float = 10000.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.body_data.flat_armor < lowest_armor:
			best_target = potential_target
			lowest_armor = potential_target.body_data.flat_armor
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.body_data.flat_armor == lowest_armor:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				lowest_armor = potential_target.body_data.flat_armor
				closest_distance = distance
	
	return best_target

func _get_highest_speed_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var highest_speed: float = 0.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.body_data.base_speed > highest_speed:
			best_target = potential_target
			highest_speed = potential_target.body_data.base_speed
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.body_data.base_speed == highest_speed:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				highest_speed = potential_target.body_data.base_speed
				closest_distance = distance
	
	return best_target

func _get_lowest_speed_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var lowest_speed: float = 10000.0
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		if potential_target.body_data.base_speed < lowest_speed:
			best_target = potential_target
			lowest_speed = potential_target.body_data.base_speed
			closest_distance = position_to_protect.distance_to(potential_target.global_position)
		elif potential_target.body_data.base_speed == lowest_speed:
			var distance: float = position_to_protect.distance_to(potential_target.global_position)
			if distance < closest_distance:
				best_target = potential_target
				lowest_speed = potential_target.body_data.base_speed
				closest_distance = distance
	
	return best_target

func _get_random_target_from_array(search_array: Array[Character]) -> Character:
	## May need to add some sorting so that this doesn't pick recently deceased targets
	if search_array.is_empty(): return null
	return search_array.pick_random()

func _get_furthest_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var furthest_distance: float = 0.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		var distance: float = position_to_protect.distance_to(potential_target.global_position)
		if distance > furthest_distance:
			furthest_distance = distance
			best_target = potential_target
	
	return best_target

func _get_closest_target_from_array(search_array: Array[Character]) -> Character:
	var best_target: Character = null
	var closest_distance: float = 10000.0
	
	for potential_target in search_array:
		if !is_instance_valid(potential_target): continue
		var distance: float = position_to_protect.distance_to(potential_target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			best_target = potential_target
	
	return best_target

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _get_aim_point() -> Vector3:
	if !target.has_method("get_velocity") || !type_data.projectile_data.perfect_accuracy: return target.global_position + Vector3.UP * target.body_data.height * 0.5
	
	var pti: Vector3 = target.global_position + Vector3.UP * target.body_data.height * 0.5
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
