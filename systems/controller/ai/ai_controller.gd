extends Node
class_name AIController

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var character: Character: set = _set_character
@export var die_with_character: bool = true: set = _set_die_with_character

@export var faction_id: int
@export var target_faction_id: int

#var target: Node3D
#var attack_range: float = 1.2
#var attack_cd: float = 1.0
#var attack_timer: float = 0.0

var direction_drift: Vector2

var attack_targets: Array[Interactable]
var attack_timer: float

var area_query_cd: float = 3.0
var area_query_timer: float
var waiting_on_area_query: bool

## IS THE AI HUNGRY???
var fed: bool
var finished_eating: bool
var bread_eaten: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_character(_character: Character) -> void:
	if character && character.killed.is_connected(queue_free): character.killed.disconnect(queue_free)
	character = _character
	if die_with_character && !character.killed.is_connected(queue_free): character.killed.connect(queue_free)
	if !character.finished_eating.is_connected(_on_character_finished_eating): character.finished_eating.connect(_on_character_finished_eating)

func _set_die_with_character(_die_with_character: bool) -> void:
	die_with_character = _die_with_character
	if is_instance_valid(character):
		if !die_with_character && character.killed.is_connected(queue_free):
			character.killed.disconnect(queue_free)
		elif die_with_character && !character.killed.is_connected(queue_free):
			character.killed.connect(queue_free)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	set_physics_process(false)
	call_deferred("_init_navigation")

func _init_navigation() -> void:
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if !is_instance_valid(character): return
	
	_update_movement(delta)
	_update_attack_targets_area_query(delta)
	_try_attack(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_movement(delta: float) -> void:
	if character.eating: return
	if Util.main.level.loading || !Util.main.level.started: return
	
	direction_drift = Vector2(clampf(direction_drift.x + (randf() - 0.5) * 0.01, -1.5, 1.5), clampf(direction_drift.y + (randf() - 0.5) * 0.01, -1.5, 1.5))
	
	var level_local_coord: Vector2 = Vector2(character.global_position.x + Util.main.level.level_dim * 0.5, character.global_position.z + Util.main.level.level_dim * 0.5).floor()
	
	var flow_vector: Vector2
	if is_instance_valid(character.grabbed_entity):
		flow_vector = Util.main.level.faction_flow_fields[faction_id][level_local_coord.y * Util.main.level.level_dim + level_local_coord.x]
		if character.global_position.distance_to(Util.main.level.centered_global_coord_from_local_coord(Util.main.level.faction_base_local_coords[faction_id])) < 1.0:
			Util.player.game_resources.bread -= 1
			queue_free()
	else:
		flow_vector = Util.main.level.faction_flow_fields[target_faction_id][level_local_coord.y * Util.main.level.level_dim + level_local_coord.x]
		
		var target_bread_pile: BreadPile = Util.main.level.faction_bread_piles[target_faction_id]
		if is_instance_valid(target_bread_pile):
			if character.global_position.distance_to(target_bread_pile.global_position) < 1.0:
				if !fed:
					var bread_to_eat: GrabbableBread = target_bread_pile.take_bread()
					if is_instance_valid(bread_to_eat):
						fed = true
						character.add_child(bread_to_eat)
						character.grab_entity(bread_to_eat)
						character.eat(bread_to_eat)
				elif finished_eating:
					var grabbable_bread: GrabbableBread = target_bread_pile.take_bread()
					if is_instance_valid(grabbable_bread):
						add_child(grabbable_bread)
						character.grab_entity(grabbable_bread)
						character.collision_layer = 16
						character.collision_mask = 17
	
	character.world_move_input = Vector3(flow_vector.x + direction_drift.x * sin(delta) * 5.0, 0.0, flow_vector.y + direction_drift.y * sin(delta) * 5.0)
	character.face_direction(character.world_move_input, delta)

func _update_attack_targets_area_query(delta: float) -> void:
	if waiting_on_area_query: return
	area_query_timer += delta
	if area_query_timer >= area_query_cd:
		area_query_timer -= area_query_cd
		waiting_on_area_query = true
		AreaQueryManager.request_area_query(self, character.global_position, character.body_data.attack_range * 3.0, 512)

## Character must be valid or this will crash
func _try_attack(delta: float) -> void:
	attack_timer = min(attack_timer + delta, character.body_data.attack_rate)
	
	var closest_target: Interactable = get_closest_target()
	if !is_instance_valid(closest_target): return
	
	DebugDraw3D.draw_line(closest_target.global_position, closest_target.global_position + Vector3.UP * 5.0, Color.RED, delta)
	
	var attack_target_position: Vector3 = Vector3(closest_target.global_position.x, 0.0, closest_target.global_position.z)
	if attack_target_position.distance_to(character.global_position) > character.body_data.attack_range: return
	
	if attack_timer == character.body_data.attack_rate:
		attack_timer = 0.0
		character.body.attack()
		print("attack!")
		if closest_target.has_method("damage"):
			var damage_data: DamageData = DamageData.new()
			damage_data.damage_strength = character.body_data.attack_damage
			closest_target.damage(damage_data, character)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_area_query(results: Array[PhysicsBody3D]) -> void:
	waiting_on_area_query = false
	for result in results:
		if result is InteractableCollider && result.get_parent().has_method("damage") && result.get_parent().team != character.team:
			attack_targets.append(result.get_parent())

func get_closest_target() -> Interactable:
	var closest_target: Interactable = null
	var closest_distance: float = 9999.0
	
	for target in attack_targets:
		if !is_instance_valid(target): continue
		var distance: float = character.global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	return closest_target

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_character_finished_eating() -> void:
	bread_eaten += 1
	if bread_eaten == character.body_data.bread_to_eat:
		queue_free()
		#finished_eating = true
	else:
		fed = false
