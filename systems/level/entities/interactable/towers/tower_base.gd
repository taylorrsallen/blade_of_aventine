class_name TowerBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var projectile_emitter: Node3D

@export var type_data: TowerTypeData

@export var level: int
@export var experience: float

var enemies: Array[Character] = []
var protect_position: bool
@export var position_to_protect: Vector3

@export var target: Node3D
var target_aim_point: Vector3

var firing_cd: float = 1.0
var firing: bool
var firing_timer: float

var built: bool
var build_timer: float
var started_building: bool

var start_position: Vector3

@export var health: float
var destroyed: bool

var waiting_on_area_query: bool
var area_query_cd: float = 0.2
var area_query_timer: float

@export var seek_targets: bool = true
@export var shoot_while_held: bool

var scepter_damage_reset_cd: float = 3.0
var scepter_damage_reset_timer: float
var scepter_damage_to_destruction: float = 3.0
var scepter_damage: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	init()

func _physics_process(delta: float) -> void:
	if !try_build_tower(delta): return
	_update(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	start_position = position
	start_position.y = 0.0
	position_to_protect = Util.main.level.centered_global_coord_from_local_coord(Util.main.level.faction_base_local_coords[faction_id])
	protect_position = true
	weight_slow_down = 2.0

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
	if !seek_targets: return
	firing_timer = min(firing_cd, firing_timer + delta * type_data.level_blueprints[level].attack_speed_multiplier)
	if !shoot_while_held && grabbed: return
	_update_enemy_area_query(delta)

func _try_fire(delta: float) -> bool:
	if !shoot_while_held && grabbed: return false
	if firing: return true
	if firing_timer >= firing_cd:
		firing_timer = 0.0
		firing = true
		return true
	else:
		return false

func _fire_projectile() -> void:
	firing = false
	if type_data.projectile_sound: SoundManager.play_pitched_3d_sfx(type_data.projectile_sound.id, type_data.projectile_sound.type, global_position, 0.9, 1.1, 0.0, 5.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_build_tower(delta: float) -> bool:
	if !started_building:
		started_building = true
		SoundManager.play_pitched_3d_sfx(2, SoundDatabase.SoundType.SFX_FOLEY, global_position  )
	
	if !built:
		build_timer += delta
		if build_timer >= type_data.build_time:
			position = start_position
			if seek_targets: firing_timer = firing_cd
			built = true
			return true
		else:
			var build_percent: float = build_timer / type_data.build_time
			health = type_data.level_blueprints[0].max_health * build_percent
			position.y = -2.0 + 2.0 * build_percent
			position.x = start_position.x + randf_range(-0.05, 0.05)
			position.z = start_position.z + randf_range(-0.05, 0.05)
		
		return false
	return true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func deal_scepter_damage() -> void:
	if destroyed: return
	
	scepter_damage += 1.0
	scepter_damage_reset_timer = 0.0
	if scepter_damage >= scepter_damage_to_destruction: destroy()

func damage(damage_data: DamageData, _source: Node) -> void:
	if destroyed: return
	
	if type_data.level_blueprints[level].max_health < 0.0: return
	health -= damage_data.damage_strength
	if health <= 0.0: destroy()

func damage_sourceless(damage_data: DamageData) -> void:
	damage(damage_data, null)

func destroy() -> void:
	destroyed = true
	
	if recipe:
		var block_pile: BlockPile = BLOCK_PILE.instantiate()
		block_pile.position = position
		block_pile.position.y = 0.0
		Util.main.level.add_tile_entity(block_pile)
		for ingredient in recipe.ingredients:
			block_pile.add_block(ingredient)
	
	queue_free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_experience(_experience: float) -> void:
	experience += _experience
	if experience >= type_data.exp_needed_for_first_level + type_data.extra_exp_requirement_per_level * level:
		level = min(type_data.level_blueprints.size() - 1, level + 1)
		experience = 0.0
	
	print("Experience: %s | Level: %s" % [experience, level])

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_enemy_area_query(delta: float) -> void:
	area_query_timer += delta
	if !waiting_on_area_query && area_query_timer >= area_query_cd:
		area_query_timer -= area_query_cd
		AreaQueryManager.request_area_query(self, global_position, type_data.level_blueprints[level].attack_range, 18)
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
	var pbi: Vector3 = projectile_emitter.global_position
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
