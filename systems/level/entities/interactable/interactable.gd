class_name Interactable extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const ATTEMPT_LANDINGS: Array[Vector3] = [
	Vector3(-1.0, 0.0, 1.0),
	Vector3(-1.0, 0.0, 0.0),
	Vector3(-1.0, 0.0, -1.0),
	Vector3(1.0, 0.0, 1.0),
	Vector3(1.0, 0.0, 0.0),
	Vector3(1.0, 0.0, -1.0),
	Vector3(0.0, 0.0, -1.0),
	Vector3(0.0, 0.0, 1.0),
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal just_highlighted(interactable: Interactable, source: Character, controller: PlayerController)
signal just_unhighlighted(interactable: Interactable, source: Character, controller: PlayerController)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var collider: InteractableCollider = $InteractableCollider
var recipe: BlockPileRecipeData

@export var interactable_data: InteractableData

@export var faction_id: int
@export var team: int

var highlighted: bool
var grabbed: bool

var destroyed: bool

var collider_that_threw_me: PhysicsBody3D
var tumbling: bool
var velocity: Vector3
var out_of_bounds_despawn_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	_update_thrown_state(delta)

func _update_thrown_state(delta: float) -> void:
	if !tumbling: return
	
	velocity.x = move_toward(velocity.x, 0.0, delta)
	velocity.z = move_toward(velocity.z, 0.0, delta)
	velocity.y -= 9.8 * delta
	
	global_position += velocity * delta
	
	if !Util.main.level.is_global_coord_in_bounds(global_position):
		out_of_bounds_despawn_timer += delta
		if out_of_bounds_despawn_timer >= 10.0: queue_free()
		return
	
	var landed: bool
	var landing_position: Vector3
	
	var results: Array[PhysicsBody3D] = AreaQueryManager.query_area(global_position, 0.5, 514, [collider_that_threw_me])
	if !results.is_empty():
		set_tumbling(false)
		
		var closest_hit: Node3D = null
		var closest_distance: float = 5.0
		for body in results:
			var distance: float = body.global_position.distance_to(global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_hit = body
		
		if closest_hit.get_parent() is Interactable:
			if interactable_data.break_when_thrown:
				destroy()
				return
			if _special_tumbling_interactable_collision(closest_hit.get_parent()): return
			landed = true
			landing_position = Util.main.level.global_coord_from_local_coord(Util.main.level.local_coord_from_global_coord(global_position))
			landing_position.y = Util.main.level.get_placement_height_at_global_coord(global_position)
		elif closest_hit is Character:
			if !is_instance_valid(closest_hit.grabbed_entity) && closest_hit.body_data.grabs_thrown_interactables:
				closest_hit.grab_entity(self)
			else:
				landed = true
				landing_position = Util.main.level.global_coord_from_local_coord(Util.main.level.local_coord_from_global_coord(global_position))
				landing_position.y = Util.main.level.get_placement_height_at_global_coord(global_position)
	else:
		if global_position.y <= Util.main.level.get_placement_height_at_global_coord(global_position):
			set_tumbling(false)
			if interactable_data.break_when_thrown:
				destroy()
				return
			else:
				landed = true
				landing_position = Util.main.level.global_coord_from_local_coord(Util.main.level.local_coord_from_global_coord(global_position))
				landing_position.y = Util.main.level.get_placement_height_at_global_coord(global_position)
	
	if landed:
		if Util.main.level.get_interactable_from_global_coord(landing_position) || landing_position.y - global_position.y > 2.0:
			var landing_found: bool
			for i in ATTEMPT_LANDINGS.size():
				landing_position = Util.main.level.global_coord_from_local_coord(Util.main.level.local_coord_from_global_coord(global_position)) + ATTEMPT_LANDINGS[i]
				landing_position.y = Util.main.level.get_placement_height_at_global_coord(landing_position)
				print(landing_position)
				
				if !Util.main.level.get_interactable_from_global_coord(landing_position) && landing_position.y - global_position.y <= 2.0:
					landing_found = true
					break
			
			if landing_found:
				Util.main.level.place_interactable_at_global_coord(landing_position, self)
			else:
				print("No valid location")
				destroy()
		else:
			Util.main.level.place_interactable_at_global_coord(landing_position, self)

func _special_tumbling_interactable_collision(_interactable: Interactable) -> bool:
	return false

func set_grabbed(active: bool) -> void:
	if active:
		grabbed = true
		_disable_collision()
	else:
		grabbed = false
		_enable_collision()

func set_tumbling(active: bool) -> void:
	if active:
		tumbling = true
		_disable_collision()
	else:
		tumbling = false
		_enable_collision()

func _enable_collision() -> void: collider.collision_layer = 513
func _disable_collision() -> void: collider.collision_layer = 0

func drop(_source: Node3D) -> void: pass

func interact(_source: Character, _controller: PlayerController) -> void: pass

func set_highlighted(active: bool, source: Character, controller: PlayerController) -> void:
	highlighted = active
	if highlighted:
		just_highlighted.emit(self, source, controller)
	else:
		just_unhighlighted.emit(self, source, controller)

func _deal_scepter_damage() -> void:
	if interactable_data.hit_sounds:
		var sound: SoundReferenceData = interactable_data.hit_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)

func destroy() -> void:
	_destroy()

func _destroy() -> void:
	destroyed = true
	queue_free()
	if interactable_data.break_sounds:
		var sound: SoundReferenceData = interactable_data.break_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
