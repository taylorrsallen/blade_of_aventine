class_name TowerBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var type_data: TowerTypeData

@export var level: int
@export var experience: float

var enemies: Array[Character] = []
var protect_position: bool
@export var position_to_protect: Vector3

@export var target: Node3D

@export var firing_cd: float = 1.0
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

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	start_position = position
	start_position.y = 0.0
	health = type_data.level_blueprints[level].max_health
	position_to_protect = Util.main.level.centered_global_coord_from_local_coord(Util.main.level.faction_base_local_coords[faction_id])
	protect_position = true
	weight_slow_down = 2.0

func _update(delta: float) -> void:
	if health < type_data.level_blueprints[level].max_health:
		health = min(health + delta, type_data.level_blueprints[level].max_health)
	
	_update_enemy_area_query(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_build_tower(delta: float) -> bool:
	if !started_building:
		started_building = true
		SoundManager.play_pitched_3d_sfx(2, SoundDatabase.SoundType.SFX_FOLEY, global_position  )
	
	if !built:
		build_timer += delta
		if build_timer >= type_data.build_time:
			position = start_position
			built = true
			return true
		else:
			var build_percent: float = build_timer / type_data.build_time
			position.y = -2.0 + 2.0 * build_percent
			position.x = start_position.x + randf_range(-0.05, 0.05)
			position.z = start_position.z + randf_range(-0.05, 0.05)
		
		return false
	return true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func damage(damage_data: DamageData, _source: Node) -> void:
	if destroyed: return
	
	if type_data.level_blueprints[level].max_health < 0.0: return
	health -= damage_data.damage_strength
	if health <= 0.0:
		destroyed = true
		
		if recipe:
			var block_pile: BlockPile = BLOCK_PILE.instantiate()
			block_pile.position = position
			block_pile.position.y = 0.0
			Util.main.level.add_tile_entity(block_pile)
			for ingredient in recipe.ingredients:
				block_pile.add_block(ingredient)
		
		queue_free()

func damage_sourceless(damage_data: DamageData) -> void:
	damage(damage_data, null)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_experience(_experience: float) -> void:
	experience += _experience
	for i in type_data.level_blueprints.size():
		if experience > type_data.level_blueprints[i].experience_for_next_level:
			level = min(type_data.level_blueprints.size() - 1, i + 1)
	
	print("Experience: %s | Level: %s" % [experience, level])

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_enemy_area_query(delta: float) -> void:
	area_query_timer += delta
	if !waiting_on_area_query && area_query_timer >= area_query_cd:
		area_query_timer -= area_query_cd
		AreaQueryManager.request_area_query(self, global_position, type_data.level_blueprints[level].attack_range, 18)

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
