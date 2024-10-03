extends Node
class_name AIController

# ////////////////////////////////////////////////////////////////////////////////////////////////
@export var character: Character: set = _set_character
var target: Node3D
var wander_target_position: Vector3

@export var die_with_character: bool = true: set = _set_die_with_character

var attack_range: float = 1.2
var attack_cd: float = 1.0
var attack_timer: float = 0.0
var wander_cd: float = 10.0
var wander_timer: float = 0.0

var update_cd: float = 0.5
var update_timer: float = 0.0

# ////////////////////////////////////////////////////////////////////////////////////////////////
func _set_character(_character: Character) -> void:
	if character && character.killed.is_connected(queue_free): character.killed.disconnect(queue_free)
	character = _character
	if die_with_character && !character.killed.is_connected(queue_free): character.killed.connect(queue_free)

func _set_die_with_character(_die_with_character: bool) -> void:
	die_with_character = _die_with_character
	if is_instance_valid(character):
		if !die_with_character && character.killed.is_connected(queue_free):
			character.killed.disconnect(queue_free)
		elif die_with_character && !character.killed.is_connected(queue_free):
			character.killed.connect(queue_free)

# ////////////////////////////////////////////////////////////////////////////////////////////////
func _ready() -> void:
	set_physics_process(false)
	call_deferred("_init_navigation")

func _init_navigation() -> void:
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if !is_instance_valid(character): return
	var level_local_coord: Vector2 = Vector2(character.global_position.x + Util.main.level.level_dim * 0.5, character.global_position.z + Util.main.level.level_dim * 0.5).floor()
	var flow_vector: Vector2 = Util.main.level.flow_field[level_local_coord.y * Util.main.level.level_dim + level_local_coord.x]
	character.world_move_input = Vector3(flow_vector.x, 0.0, flow_vector.y)
	character.face_direction(character.world_move_input, delta)
	#if level_local_coord.distance_to(Util.main.level.target_local_coord) < 2.0: character._on_killed()
	
	#if !is_instance_valid(Util.player): return
	#if !is_instance_valid(Util.player.character): return
	#
	#target = Util.player.character
	#var distance_to_target: float = character.global_position.distance_to(target.global_position)
	#
	#attack_timer += delta
	#
	#if is_instance_valid(target):
		#if character.body.global_basis.z.dot((target.global_position - character.global_position).normalized()) < -0.5:
			#character.look_at_target(target)
		#else:
			#character.look_forward()
		#
		#if distance_to_target > attack_range:
			#update_timer += delta
			#if update_timer >= update_cd:
				#update_timer -= update_cd
				#character.navigation_agent_3d.target_position = target.global_position
				#if !character.navigation_agent_3d.is_target_reachable():
					#return
				#else:
					#var next_pos: Vector3 = character.navigation_agent_3d.get_next_path_position()
					#character.world_move_input = next_pos - character.global_position
					#character.world_move_input.y = 0.0
			#character.face_direction(character.world_move_input, delta)
		#elif distance_to_target < attack_range * 0.5:
			#character.world_move_input = character.global_position - target.global_position
			#character.world_move_input.y = 0.0
			#character.face_direction(target.global_position - character.global_position, delta)
		#else:
			#character.world_move_input = Vector3.ZERO
			#character.face_direction(target.global_position - character.global_position, delta)
			#if attack_timer > attack_cd:
				##character.body.attack()
				#attack_timer = 0.0
