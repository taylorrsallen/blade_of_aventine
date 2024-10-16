class_name Pickup extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var body: StaticBody3D = $Body

@export var drop_curve: Curve
@export var direction: Vector3
@export var distance: float = 3.0
@export var time_to_grounded: float = 1.0
@export var rotation_speed: Vector3

var blink_cd: float = 0.25
var blink_timer: float
@export var despawn_cd: float = 20.0
var lifetime_timer: float

var suction_speed: float
var suction_target: Node3D

@export var pickup_data: PickupData: set = _set_pickup_data

var time_until_suction: float = 0.2
var time_until_suction_timer: float

var landing_height: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_pickup_data(_pickup_data: PickupData) -> void:
	pickup_data = _pickup_data
	if pickup_data.model:
		for child in $Body/Model.get_children(): child.queue_free()
		$Body/Model.add_child(pickup_data.model.instantiate())

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	direction = Vector3(randf() - 0.5, 0.0, randf() - 0.5).normalized()
	rotation_speed = Vector3((randf() - 0.5) * 40.0, (randf() - 0.5) * 40.0, (randf() - 0.5) * 40.0)
	landing_height = Util.main.level.get_placement_height_at_global_coord(global_position + direction * distance)
	if pickup_data && pickup_data.spawn_sounds:
		var sound: SoundReferenceData = pickup_data.spawn_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db)

func _physics_process(delta: float) -> void:
	lifetime_timer += delta
	var time_left: float = despawn_cd - lifetime_timer
	if time_left < 5.0:
		if time_left < 1.0:
			blink_cd = 0.05
		elif time_left < 2.5:
			blink_cd = 0.1
		elif time_left < 4.0:
			blink_cd = 0.2
		
		blink_timer += delta
		if blink_timer >= blink_cd:
			blink_timer -= blink_cd
			$Body/Model.visible = !$Body/Model.visible
	
	if lifetime_timer >= despawn_cd:
		if pickup_data.metadata.has("bread"): EventBus.bread_lost.emit()
		queue_free()
	
	time_until_suction_timer += delta
	if time_until_suction_timer >= time_until_suction && is_instance_valid(suction_target):
		suction_speed += delta
		var target_position: Vector3 = suction_target.global_position + Vector3.UP * 0.5
		$Body.global_position = $Body.global_position.move_toward(target_position, suction_speed)
		$Body.rotate_x(delta * rotation_speed.x)
		$Body.rotate_y(delta * rotation_speed.y)
		$Body.rotate_z(delta * rotation_speed.z)
		if $Body.global_position.distance_to(target_position) < 0.5:
			var sound_ref: SoundReferenceData = pickup_data.pickup_sounds.pick_random()
			SoundManager.play_pitched_3d_sfx(sound_ref.id, sound_ref.type, body.global_position, 0.9, 1.1, 0.0, 5.0)
			if suction_target.has_method("receive_pickup"): suction_target.receive_pickup(pickup_data)
			queue_free()
	elif lifetime_timer < time_to_grounded:
		var anim_percent: float = lifetime_timer / time_to_grounded
		$Body.position = direction * distance * anim_percent
		$Body.position.y = drop_curve.sample(anim_percent) * 2.0 + lerpf(global_position.y, landing_height - global_position.y, anim_percent)
		$Body.rotate_x(delta * rotation_speed.x)
		$Body.rotate_y(delta * rotation_speed.y)
		$Body.rotate_z(delta * rotation_speed.z)
	
	if !is_instance_valid(suction_target): body.collision_layer = 8

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func take(taker: Node3D) -> void:
	suction_target = taker
	body.collision_layer = 0
