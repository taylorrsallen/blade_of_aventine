class_name Character extends RigidBody3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal jumped()
signal landed(force: float)
signal killed()
signal pickup_received(pickup: PickupData)
signal finished_eating()
signal entered_gateway(gateway_data: GatewayData)
signal body_data_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum CharacterFlag {
	GROUNDED,
	WALK,
	SPRINT,
	TUMBLING,
	NOCLIP,
	DEAD,
}

enum CharacterAction {
	PRIMARY,
	PRIMARY_ALT,
	SECONDARY,
	SECONDARY_ALT,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const RANDOM_NOISES: PackedScene = preload("res://systems/character/noises/random_noises.scn")
const EMPEROR: CharacterBodyData = preload("res://resources/bodies/emperor.res")
var PICKUP: PackedScene = load("res://systems/level/entities/pickup/pickup.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## COMPOSITION
#@onready var character_actions: CharacterActions = $CharacterActions
@onready var nav_collider: CollisionShape3D = $NavCollider
@onready var spring_ray: RayCast3D = $NavCollider/SpringRay

@onready var body: CharacterBody
@onready var body_container: Node3D = $BodyContainer
@onready var body_center_pivot: Node3D = $BodyContainer/BodyCenterPivot

@onready var camera_socket: Node3D

## DATA
@export var body_data: CharacterBodyData: set = _set_character_body_data
var drops_data: DropsData

## FLAGS
var flags: int

## MOVEMENT
@export var ride_height: float = 1.22
@export var ride_spring_strength: float = 220.0
@export var ride_spring_damper: float = 20.0
@export var upright_rotation: Quaternion = Quaternion.IDENTITY
@export var upright_spring_strength: float = 25.0
@export var upright_spring_damper: float = 3.0

var look_basis: Basis
var look_direction: Vector3
var look_scalar: float

var move_input: Vector3
var world_move_input: Vector3
var desired_facing: Vector3
var move_direction: Vector3
@export var move_direction_lerp_speed: float = 10.0

@export var walk_speed: float = 3.0
@export var jog_speed: float = 5.0
@export var sprint_speed: float = 7.0
var current_speed: float = walk_speed

@export var jump_velocity: float = 4.5

var last_velocity: Vector3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var attack_timer: float

## STATS
var health: float

## VEHICLE
@export var vehicle: Node3D

## COLLISION
var default_collision_mask: int

## GRAB
var grabbed_entity: Interactable

## AI INTERACTION
@export var team: int
var previous_position: Vector3
var effective_velocity: Vector3

## AUDIO
var random_noises: RandomNoises

## EATING BREAD
var eating: bool
var eating_timer: float
var eating_sound_timer: float

var readied: bool

var unstuck_speed_mod: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func is_flag_on(flag: CharacterFlag) -> bool: return Util.is_flag_on(flags, flag)
func set_flag_on(flag: CharacterFlag) -> void: flags = Util.set_flag_on(flags, flag)
func set_flag_off(flag: CharacterFlag) -> void: flags = Util.set_flag_off(flags, flag)
func set_flag(flag: CharacterFlag, active: bool) -> void: flags = Util.set_flag(flags, flag, active)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
#func _set_stat_data(_stat_data: CharacterStatData) -> void:
	#if stat_data: stat_data.killed.disconnect(_on_killed)
	#stat_data = _stat_data
	#if !stat_data.killed.is_connected(_on_killed): stat_data.killed.connect(_on_killed)

func _set_character_body_data(_body_data: CharacterBodyData) -> void:
	body_data = _body_data
	if !readied: return
	
	body_center_pivot = $BodyContainer/BodyCenterPivot
	for child in body_center_pivot.get_children(): child.free()
	
	body_center_pivot.position.y = body_data.height * 0.5
	body = body_data.body_scene.instantiate()
	body_center_pivot.add_child(body)
	body.position.y = -body_data.height * 0.5
	
	camera_socket = Node3D.new()
	body_center_pivot.add_child(camera_socket)
	camera_socket.position.y = body_data.height * 0.3
	
	jog_speed = body_data.base_speed
	sprint_speed = body_data.sprint_speed
	
	if body_data.random_noises_pool:
		if is_instance_valid(random_noises): random_noises.queue_free()
		random_noises = RANDOM_NOISES.instantiate()
		random_noises.random_sound_pool = body_data.random_noises_pool
		add_child(random_noises)
	
	drops_data = body_data.drops_data
	body.animation_data = body_data.character_body_animation_data
	body.data = body_data
	
	if body_data != EMPEROR:
		health = body_data.max_health + body_data.max_health * Util.main.level.waves_passed * 0.05
		#print("Spawned with %s health" % health)
	else:
		health = body_data.max_health
	
	$NavCollider.shape.radius = body_data.radius
	$DamageableArea3D/CollisionShape3D.shape.radius = body_data.radius
	
	mass = body_data.mass
	
	if body_data.body_type == CharacterBodyData.BodyType.FLYING:
		ride_height = 4.0
		$NavCollider/SpringRay.target_position.y = -6.0
		spring_ray.collision_mask = 2048

func get_eye_target() -> Node3D:
	return body.get_eye_target()

func get_body_center_pos() -> Vector3:
	return body_center_pivot.global_position

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$NavCollider.shape = $NavCollider.shape.duplicate()
	$DamageableArea3D/CollisionShape3D.shape = $DamageableArea3D/CollisionShape3D.shape.duplicate()
	readied = true
	_set_character_body_data(body_data)
	default_collision_mask = collision_mask
	
	#character_actions.init(body.animation_tree)

func _physics_process(delta: float) -> void:
	attack_timer = min(attack_timer + delta, body_data.attack_rate)
	effective_velocity = global_position - previous_position
	previous_position = global_position
	
	if grabbed_entity:
		if !is_instance_valid(grabbed_entity): drop_grabbed_entity()
	
	if !vehicle:
		_update_movement(delta)
	else:
		pass # Send inputs to vehicle, just like how Controller sends input to Character
	
	if eating:
		_update_eating(delta)
	else:
		if is_instance_valid(grabbed_entity):
			_update_grabbed_entity()
		else:
			grabbed_entity = null

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func use_primary() -> void:
	pass

func use_secondary() -> void:
	pass

func use_interact() -> void:
	print("INTERACT")

func use_item() -> void:
	print("ITEM")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func grab_entity(entity: Interactable) -> void:
	if (grabbed_entity): drop_grabbed_entity()
	if !is_instance_valid(entity): return
	entity.set_grabbed(true)
	grabbed_entity = entity
	body.set_grabbing(true)

func drop_grabbed_entity() -> Interactable:
	if !is_instance_valid(grabbed_entity):
		grabbed_entity = null
		return null
	grabbed_entity.set_grabbed(false)
	var entity: Interactable = grabbed_entity
	grabbed_entity.drop(self)
	grabbed_entity = null
	body.set_grabbing(false)
	return entity

func _update_grabbed_entity() -> void:
	grabbed_entity.global_position = global_position + Vector3.UP * body_data.height
	grabbed_entity.global_rotation = body_center_pivot.global_rotation
	if grabbed_entity is TowerBase:
		grabbed_entity.start_position = grabbed_entity.global_position
		grabbed_entity.current_animation_position = grabbed_entity.global_position

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_sprinting(active: bool) -> void:
	set_flag(CharacterFlag.SPRINT, active)
	body.set_sprinting(active)

func toggle_sprinting() -> void:
	if is_flag_on(CharacterFlag.SPRINT):
		body.set_sprinting(false)
		set_flag_off(CharacterFlag.SPRINT)
	else:
		body.set_sprinting(true)
		set_flag_on(CharacterFlag.SPRINT)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func face_direction(direction: Vector3, delta: float) -> void:
	if body.can_walk():
		Util.rotate_yaw_to_target(delta * move_direction_lerp_speed, body_container, body_container.global_position + direction)
		body_center_pivot.basis = Basis.IDENTITY
		nav_collider.basis = Basis.IDENTITY

func _update_movement(delta: float) -> void:
	if eating:
		current_speed = 0.0
	else:
		if is_flag_on(CharacterFlag.WALK):
			current_speed = walk_speed
		elif is_flag_on(CharacterFlag.SPRINT):
			current_speed = sprint_speed
		else:
			current_speed = jog_speed
	
	if is_instance_valid(grabbed_entity):
		if grabbed_entity.interactable_data:
			current_speed -= grabbed_entity.interactable_data.weight_slow_down
	
	_update_movement_grounded(delta)

func _update_movement_grounded(delta: float) -> void:
	#_update_upright_rotation()
	#_update_upright_force()
	_update_ride_force()
	
	if is_flag_on(CharacterFlag.GROUNDED) && last_velocity.y < -1.0: landed.emit(-last_velocity.y)
	
	if !is_flag_on(CharacterFlag.GROUNDED):
		linear_velocity.y -= gravity * delta
	elif world_move_input.y > 0.0 && body.can_walk():
		linear_velocity.y = jump_velocity
		jumped.emit()
	
	if is_flag_on(CharacterFlag.GROUNDED):
		if body.can_walk():
			move_direction = lerp(move_direction, Vector3(world_move_input.x, 0.0, world_move_input.z).normalized(), delta * move_direction_lerp_speed)
		else:
			move_direction = lerp(move_direction, Vector3.ZERO, delta * move_direction_lerp_speed)
		
		if move_direction != Vector3.ZERO:
			linear_velocity.x = move_direction.x * current_speed
			linear_velocity.z = move_direction.z * current_speed
			body.set_walking(true)
		else:
			linear_velocity.x = move_toward(linear_velocity.x, 0.0, current_speed)
			linear_velocity.z = move_toward(linear_velocity.z, 0.0, current_speed)
			body.set_walking(false)
	
	if world_move_input == Vector3.ZERO:
		set_flag_off(CharacterFlag.SPRINT)
		body.set_walking(false)
	
	last_velocity = linear_velocity

func _update_upright_rotation() -> void:
	var look_transform: Transform3D = Transform3D.IDENTITY

	if move_input == Vector3.ZERO:
		var forward = -basis.z + global_position
		forward.y = 0.0
		forward = forward.normalized()
		look_transform = look_transform.looking_at(forward)
	elif move_input.x == 0.0 && move_input.z == 0.0:
		return
	else:
		var input_normalized = move_direction
		input_normalized.y = 0.0
		input_normalized = input_normalized.normalized()
		
		var look_at_vec: Vector3 = Vector3(input_normalized.x, -0.1 * input_normalized.length(), input_normalized.z)
		look_transform = look_transform.looking_at(look_at_vec)
	
	upright_rotation = look_transform.basis.get_rotation_quaternion()
	#rotation = look_transform.basis.get_euler()

func _update_upright_force() -> void:
	var current_rotation = Quaternion.from_euler(rotation)
	var to_goal: Quaternion = Util.shortest_rotation(upright_rotation, current_rotation)
	
	var axis: Vector3 = to_goal.get_axis()
	var angle: float = to_goal.get_angle()
	axis = axis.normalized()
	
	constant_torque = (axis * (angle * upright_spring_strength)) - (angular_velocity * upright_spring_damper)

func _update_ride_force() -> void:
	if spring_ray.is_colliding():
		var hit_point: Vector3 = spring_ray.get_collision_point()
		var hit_toi: float = (hit_point - spring_ray.global_position).length()
		var other_collider: Node3D = spring_ray.get_collider()
		
		var grounded: bool = hit_toi <= ride_height + ride_height * 0.1
		set_flag(CharacterFlag.GROUNDED, grounded)
		body.grounded = grounded
		if !is_flag_on(CharacterFlag.GROUNDED):
			constant_force = Vector3.ZERO
			return
		
		var other_linvel: Vector3 = other_collider.velocity if other_collider is RigidBody3D else Vector3.ZERO
		var ray_direction_velocity: float = Vector3.DOWN.dot(linear_velocity)
		var other_direction_velocity: float = Vector3.DOWN.dot(other_linvel)
		var relative_velocity: float = ray_direction_velocity - other_direction_velocity
		
		var x: float = hit_toi - ride_height
		var spring_force: float = (x * ride_spring_strength) - (relative_velocity * ride_spring_damper)
		
		constant_force = Vector3.DOWN * spring_force
		
		if other_collider is RigidBody3D:
			pass
	else:
		set_flag_off(CharacterFlag.GROUNDED)
		constant_force = Vector3.ZERO

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_killed() -> void:
	if drops_data: drops_data.drop(global_position)
	
	if is_instance_valid(grabbed_entity):
		var drop_entity: Interactable = drop_grabbed_entity()
		Util.main.level.place_interactable_at_global_coord(drop_entity.global_position, drop_entity)
	
	if body_data.die_sounds:
		var sound: SoundReferenceData = body_data.die_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
	
	
	
	body.die()
	
	killed.emit()
	queue_free()

func _on_damageable_area_3d_damaged(damage_data: DamageData, _area_id: int, source: Node) -> void:
	damage(damage_data, source)

func damage(damage_data: DamageData, source: Node) -> void:
	if is_flag_on(CharacterFlag.DEAD): return
	
	body.stagger()
	if body_data.hit_sounds:
		var sound: SoundReferenceData = body_data.hit_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
	
	if damage_data.damage_type == DamageData.DamageType.ELEMENTAL:
		health -= damage_data.damage_strength
	else:
		health -= clampf(damage_data.damage_strength - body_data.flat_armor, 0.0, 999.9)
	
	if health <= 0.0:
		set_flag_on(CharacterFlag.DEAD)
		if is_instance_valid(source) && source.has_method("add_experience"):
			source.add_experience(body_data.get_experience_value())
		_on_killed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func receive_pickup(pickup: PickupData) -> void:
	pickup_received.emit(pickup)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func eat(grabbable_bread: GrabbableBread) -> void:
	body.set_eating(grabbable_bread)
	world_move_input = Vector3.ZERO
	eating = true

func _update_eating(delta: float) -> void:
	eating_sound_timer += delta
	if eating_sound_timer >= body_data.eating_noise_cd:
		eating_sound_timer -= body_data.eating_noise_cd
		var sound_reference: SoundReferenceData = body_data.eating_sounds_pool.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound_reference.id, sound_reference.type, global_position, 0.9, 1.1, 0.0, 6.0)
	
	eating_timer += delta
	if eating_timer >= body_data.time_to_eat:
		eating_timer -= body_data.time_to_eat
		EventBus.bread_lost.emit()
		if is_instance_valid(grabbed_entity): grabbed_entity.queue_free()
		body.set_eating(null)
		finished_eating.emit()
		eating = false

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_velocity() -> Vector3:
	if effective_velocity.length() < 0.01: return Vector3.ZERO
	return linear_velocity

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_attack() -> bool:
	if attack_timer == body_data.attack_rate:
		attack_timer = 0.0
		body.attack()
		if body_data.attack_sounds:
			var sound: SoundReferenceData = body_data.attack_sounds.pool.pick_random()
			SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
		return true
	return false
