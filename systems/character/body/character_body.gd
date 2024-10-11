class_name CharacterBody extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal damaged(damage_data: DamageData, area_id: int)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var animation_tree: AnimationTree = $AnimationTree
var animation_data: CharacterBodyAnimationData: set = _set_animation_data
var animation_players: Array[CharacterAnimationTypePlayer]

@onready var right_hand: BoneAttachment3D = $Model/root/Skeleton3D/RightHand
@onready var left_hand: BoneAttachment3D = $Model/root/Skeleton3D/LeftHand

var left_footstep: bool

var grounded: bool
var is_free: bool = true

var eating_node: Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_animation_data(_animation_data: CharacterBodyAnimationData) -> void:
	animation_data = _animation_data
	animation_players.resize(animation_data.animations.size())
	for i in animation_data.animations.size():
		animation_players[i] = CharacterAnimationTypePlayer.new()
		animation_players[i].data = animation_data.animations[i]
	
	animation_players[0].target = 1.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	_update(delta)

func _update(delta: float) -> void:
	if !animation_data: return
	for animation_player in animation_players:
		animation_player.update_blend(delta, animation_tree)
		animation_player.advance_step(delta, animation_tree)
	
	if is_instance_valid(eating_node):
		eating_node.global_position = right_hand.global_position + Vector3(0.087, 0.087, -0.101)
		eating_node.global_rotation = right_hand.global_rotation
		eating_node.rotation_degrees += Vector3(72.3, -45.5, -27.5)
	
	if grounded && animation_data.footsteps && animation_players[CharacterAnimationTypeData.CharacterAnimationType.WALK].blend > 0.1:
		var current_walk_step: int = animation_players[CharacterAnimationTypeData.CharacterAnimationType.WALK].current_step
		if !left_footstep && current_walk_step == 0:
			left_footstep = true
			_play_footstep_sfx()
		elif left_footstep && current_walk_step == 4:
			left_footstep = false
			_play_footstep_sfx()

func _play_footstep_sfx() -> void:
	var terrain_tile: TerrainTileData = Util.main.level.get_terrain_tile_at_global_coord(global_position)
	if terrain_tile.footstep_sounds:
		var sound: SoundReferenceData = terrain_tile.footstep_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, -12.0, 5.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## Bool
func can_walk() -> bool: return is_free

## One time animations
func attack() -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.ATTACK].target = 1.0
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.ATTACK].current_step = 0.0
func special() -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.SPECIAL].target = 1.0
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.SPECIAL].current_step = 0.0
func stagger() -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.STAGGER].target = 1.0
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.STAGGER].current_step = 0.0
func die() -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.DIE].target = 1.0
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.DIE].current_step = 0.0
	
	reparent(Util.main)
	await get_tree().create_timer(5.0).timeout
	for i in 20:
		global_position.y -= 0.05
		await get_tree().create_timer(0.1).timeout
	queue_free()

## Toggle animations
func set_eating(_node: Node3D) -> void:
	if is_instance_valid(eating_node): eating_node.queue_free()
	eating_node = _node
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.EAT].target = 1.0 if is_instance_valid(_node) else 0.0

func set_walking(_active: bool) -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.WALK].target = 1.0 if _active else 0.0
func set_sprinting(_active: bool) -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.SPRINT].target = 1.0 if _active else 0.0
func set_grabbing(_active: bool) -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.GRAB].target = 1.0 if _active else 0.0
func set_dancing(_active: bool) -> void:
	if !animation_data: return
	animation_players[CharacterAnimationTypeData.CharacterAnimationType.DANCE].target = 1.0 if _active else 0.0
