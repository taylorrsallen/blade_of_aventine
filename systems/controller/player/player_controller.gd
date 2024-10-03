extends Node
class_name PlayerController

# ////////////////////////////////////////////////////////////////////////////////////////////////
enum PlayerControllerFlag {
	CURSOR_VISIBLE,
	MENU_VISIBLE,
}

enum {
	CONTROL_KEYBOARD,
	CONTROL_SONY,
	CONTROL_NINTENDO,
	CONTROL_XBOX,
}

enum Perspective {
	FPS,
	TPS,
}

# ////////////////////////////////////////////////////////////////////////////////////////////////
const SPLITSCREEN_VIEW_SCN: PackedScene = preload("res://systems/controller/player/splitscreen_view.scn")
const SHADER_VIEW_SCN: PackedScene = preload("res://systems/controller/player/shader_view.scn")
const CAMERA_RIG: PackedScene = preload("res://systems/camera/camera_rig.scn")

# ////////////////////////////////////////////////////////////////////////////////////////////////
## COMPOSITION
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

## FLAGS
@export var flags: int

## DATA
var local_id: int

## INPUT
@export var perspective: Perspective: set = _set_perspective

@export var raw_move_input: Vector3
@export var world_move_input: Vector3
@export var look_input: Vector2
@export var desired_facing: Vector3

var previous_cursor_pos: Vector2
@export var cursor_pos: Vector2
@export var cursor_world_entity: Node3D
@export var cursor_world_pos: Vector3

var focus_world_entity: Node3D
var focus_world_pos: Vector3
var can_interact: bool

@onready var selection_cursor: Node3D = $SelectionCursor
@onready var aventine_highlighter: Node3D = $aventine_highlighter
var focused_interactable_entity: Interactable
var selection_position: Vector3

## VIEW
@onready var camera_view_layer: CanvasLayer = $CameraViewLayer
@export var splitscreen_view: SplitscreenView
@onready var shader_view_layer: CanvasLayer = $ShaderViewLayer
@export var shader_view: ShaderView
@onready var hud_view_layer: CanvasLayer = $HUDViewLayer
@onready var hud_view: Control = $HUDViewLayer/HUDView

@export var camera_rig: CameraRig

## CHARACTER
@export var character: Character

# ////////////////////////////////////////////////////////////////////////////////////////////////
func _set_perspective(_perspective: Perspective) -> void:
	if perspective == _perspective: return
	perspective = _perspective
	if is_instance_valid(camera_rig): _init_camera_rig()

# ////////////////////////////////////////////////////////////////////////////////////////////////
func init() -> void:
	Util.main.game_started.connect(_on_game_started)
	
	spawn_camera_rig()
	_assign_default_keyboard_controls(0, 0)
	set_cursor_captured()

func _physics_process(delta: float) -> void:
	_update_movement_input()
	
	#if Input.is_action_just_pressed("toggle_perspective_" + str(local_id)):
		#perspective = Perspective.FPS if perspective == Perspective.TPS else Perspective.TPS
	
	if !get_window().has_focus():
		set_cursor_visible()
	else:
		set_cursor_visible()
		#set_cursor_captured()
	
	if is_instance_valid(character):
		if Input.is_action_just_released("zoom_in_0"):
			camera_rig.zoom = clampf(camera_rig.zoom - 0.5, 0.5, 7.0)
		elif Input.is_action_just_released("zoom_out_0"):
			camera_rig.zoom = clampf(camera_rig.zoom + 0.5, 0.5, 7.0)
		
		selection_position = (character.global_position + camera_rig.get_yaw_forward()).floor()
		selection_position.y = 0.0
		
		if is_instance_valid(character.grabbed_entity):
			if get_interactable_from_global_coord(selection_position):
				selection_cursor.hide()
				aventine_highlighter.show()
				aventine_highlighter.global_position = selection_position + Vector3(0.5, 0.0, 0.5)
			else:
				aventine_highlighter.hide()
				selection_cursor.show()
				selection_cursor.position = selection_position + Vector3(0.5, 0.0, 0.5)
		else:
			selection_cursor.hide()
			if is_instance_valid(focused_interactable_entity):
				aventine_highlighter.show()
				aventine_highlighter.global_position = focused_interactable_entity.global_position
			else:
				aventine_highlighter.hide()
		
		#DebugDraw3D.draw_aabb(AABB(selection_position, Vector3.ONE), Color.ORANGE, delta)
		#DebugDraw3D.draw_line(selection_position, selection_position + Vector3.UP * 5.0, Color.ORANGE, 0.016)
		
		AreaQueryManager.request_area_query(self, character.global_position, 1.0, 512)
		
		#gui_hud.show()
		
		if is_instance_valid(focus_world_entity) && focus_world_pos.distance_to(character.get_body_center_pos()) < 2.0:
			can_interact = true
		else:
			can_interact = false
		
		_update_character_input(delta)
		_update_hud()
		
		character.set_yaw_look_basis(camera_rig.get_yaw_rotation())
		character.set_pitch_look_basis(camera_rig.get_pitch_rotation())
		
		if perspective == Perspective.FPS:
			character.face_direction(camera_rig.get_yaw_forward(), delta)
		else:
			character.face_direction(world_move_input, delta)
		
		if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
			var cursor_movement: Vector2 = get_viewport().size * 0.5 - get_viewport().get_mouse_position()
			get_viewport().warp_mouse(get_viewport().size * 0.5)
			camera_rig.apply_inputs(raw_move_input, cursor_movement, delta)
			camera_rig.apply_camera_rotation()
			look_input = Vector2.ZERO
			_update_focus()
		else:
			_update_cursor_pos()
			#_update_cursor_input()
	else:
		pass
		#gui_hud.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: look_input = Vector2(-event.relative.x, -event.relative.y)

# ////////////////////////////////////////////////////////////////////////////////////////////////
func is_flag_on(flag: PlayerControllerFlag) -> bool: return Util.is_flag_on(flags, flag)
func set_flag_on(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_on(flags, flag)
func set_flag_off(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_off(flags, flag)
func set_flag(flag: PlayerControllerFlag, active: bool) -> void: flags = Util.set_flag(flags, flag, active)

# ////////////////////////////////////////////////////////////////////////////////////////////////
## For removing non-host local players from the game
func remove() -> void:
	if local_id == 0: return

# ////////////////////////////////////////////////////////////////////////////////////////////////
func update_area_query(results: Array[PhysicsBody3D]) -> void:
	var interactables: Array[Interactable] = []
	for result in results:
		if result is InteractableCollider:
			interactables.append(result.get_parent())
	
	focused_interactable_entity = null
	var closest_distance: float = 100.0
	for interactable in interactables:
		#DebugDraw3D.draw_line(interactable.global_position, interactable.global_position + Vector3.UP * 5.0, Color.RED, 0.016)
		var distance: float = character.global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			focused_interactable_entity = interactable
			closest_distance = distance

# ////////////////////////////////////////////////////////////////////////////////////////////////
func _update_hud() -> void:
	pass
	#gui_hud.health_bar.value = character.stat_data.health
	#gui_hud.health_bar.value_max = character.stat_data.health_max
	#gui_hud.stamina_bar.value = max(character.stat_data.stamina, 0.0)
	#gui_hud.stamina_bar.value_max = character.stat_data.stamina_max

func _update_character_input(_delta: float) -> void:
	character.look_basis = camera_rig.rotation_target.basis
	character.look_direction = camera_rig.get_camera_forward()
	character.move_input = raw_move_input
	character.world_move_input = world_move_input
	character.desired_facing = desired_facing
	character.look_scalar = camera_rig.get_look_up_down_scalar()
	
	if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		if Input.is_action_just_pressed("primary_" + str(local_id)):
			if !character.grabbed_entity:
				if focused_interactable_entity:
					if focused_interactable_entity is BlockPile:
						character.grab_entity(focused_interactable_entity.take_block())
					elif focused_interactable_entity is TowerBase:
						if focused_interactable_entity.built:
							character.grab_entity(focused_interactable_entity)
					else:
						character.grab_entity(focused_interactable_entity)
			else:
				var selection_interactable: Interactable = get_interactable_from_global_coord(selection_position)
				if selection_interactable:
					if selection_interactable is BlockPile && character.grabbed_entity is BlockPile:
						var grabbed_block_pile: BlockPile = character.drop_grabbed_entity()
						selection_interactable.add_block_pile(grabbed_block_pile)
				else:
					var entity: Interactable = character.drop_grabbed_entity()
					entity.global_position = selection_position + Vector3(0.5, 0.0, 0.5)
				#print("Terrain: %s" % Util.main.level.get_terrain_id_at_global_coord(selection_position))
				
			
			character.use_primary()
		
		if Input.is_action_just_pressed("secondary_" + str(local_id)): character.use_secondary()
		#if Input.is_action_just_pressed("item_" + str(local_id)): character.use_item()
		#if Input.is_action_just_pressed("interact_" + str(local_id)):
			#if can_interact && focus_world_entity.has_method("interact"):
				#focus_world_entity.interact(character, focus_world_pos, self)
	
	if Input.is_action_pressed("sprint_" + str(local_id)): character.set_sprinting(true)
	if Input.is_action_just_released("sprint_" + str(local_id)): character.set_sprinting(false)
	
	if character.current_speed > character.jog_speed && character.move_input != Vector3.ZERO:
		camera_rig.fov_mod = (character.current_speed - character.jog_speed) * 1.5
	else:
		camera_rig.fov_mod = 0.0

func get_interactable_from_global_coord(global_coord: Vector3) -> Interactable:
	var entities_in_selection: Array[PhysicsBody3D] = AreaQueryManager.query_area(global_coord + Vector3(0.5, 0.0, 0.5), 0.1, 512)
	if !entities_in_selection.is_empty(): return entities_in_selection[0].get_parent()
	return null

func _update_movement_input() -> void:
	desired_facing = camera_rig.get_yaw_forward()
	
	var raw_horizontal_move_input: Vector2 = Input.get_vector("move_left_" + str(local_id), "move_right_" + str(local_id), "move_forward_" + str(local_id), "move_back_" + str(local_id)).normalized()
	raw_move_input.x = raw_horizontal_move_input.x
	raw_move_input.z = raw_horizontal_move_input.y
	
	world_move_input = camera_rig.get_yaw_local_vector3(raw_move_input)

func _update_focus() -> void:
	var new_focused_entity: Node3D = camera_rig.get_focused_entity()
	
	focus_world_entity = new_focused_entity
	focus_world_pos = camera_rig.focus_position

func _update_cursor_pos() -> void:
	cursor_pos = get_viewport().get_mouse_position()
	
	_bound_cursor_pos()
	
	var space_state: PhysicsDirectSpaceState3D = get_tree().root.get_world_3d().direct_space_state
	var ray_origin: Vector3 = camera_rig.camera_3d.project_ray_origin(cursor_pos)
	var ray_end: Vector3 = ray_origin + camera_rig.camera_3d.project_ray_normal(cursor_pos) * 100.0
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_query.collision_mask = 1
	var result = space_state.intersect_ray(ray_query)
	
	if result.is_empty():
		cursor_world_entity = null
	else:
		cursor_world_entity = result["collider"]
		cursor_world_pos = result["position"]
	
	#if !the_one_single_mouse_user:
		#Input.mouse

func _bound_cursor_pos() -> void:
	if cursor_pos.x < 0.0:
		cursor_pos.x = 0.0
	else: if cursor_pos.x > splitscreen_view.size.x:
		cursor_pos.x = splitscreen_view.size.x
	
	if cursor_pos.y < 0.0:
		cursor_pos.y = 0.0
	else: if cursor_pos.y > splitscreen_view.size.y:
		cursor_pos.y = splitscreen_view.size.y

# ////////////////////////////////////////////////////////////////////////////////////////////////
func toggle_cursor_visible() -> void:
	if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		set_cursor_visible()
	else:
		set_cursor_captured()

func set_cursor_visible() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_flag_on(PlayerControllerFlag.CURSOR_VISIBLE)

func set_cursor_captured() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	set_flag_off(PlayerControllerFlag.CURSOR_VISIBLE)

# ////////////////////////////////////////////////////////////////////////////////////////////////
# CHARACTER
func respawn_character() -> void:
	const CHARACTER_SCN: PackedScene = preload("res://systems/character/character.scn")
	character = CHARACTER_SCN.instantiate()
	
	character.position = Util.main.spawn_point
	character.team = 1
	
	add_child(character)
	_init_camera_rig()
	set_cursor_captured()

# ////////////////////////////////////////////////////////////////////////////////////////////////
# GAME START
func _on_game_started() -> void:
	respawn_character()

# ////////////////////////////////////////////////////////////////////////////////////////////////
# SPLITSCREEN
func update_splitscreen_view(player_count: int, horizontal: bool = true) -> void:
	match player_count:
		1: _set_view_anchors()
		2: _update_2_player_splitscreen_view(horizontal)
		3: _update_3_player_splitscreen_view(horizontal)
		4: _update_4_player_splitscreen_view()
		_: pass

# ------------------------------------------------------------------------------------------------
# PRIVATE SPLITSCREEN
func _set_view_anchors(left: float = 0.0, right: float = 1.0, bottom: float = 1.0, top: float = 0.0) -> void:
	_set_control_view_anchors(splitscreen_view, left, right, bottom, top)
	_set_control_view_anchors(shader_view, left, right, bottom, top)
	_set_control_view_anchors(hud_view, left, right, bottom, top)
	#_set_control_view_anchors(gui_3d_view, left, right, bottom, top)

func _set_control_view_anchors(control: Control, left: float = 0.0, right: float = 1.0, bottom: float = 1.0, top: float = 0.0) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom

func _update_2_player_splitscreen_view(horizontal: bool) -> void:
	if local_id == 0:
		if horizontal:
			_set_view_anchors(0.0, 1.0, 0.5, 0.0)
		else:
			_set_view_anchors(0.0, 0.5, 1.0, 0.0)
	else:
		if horizontal:
			_set_view_anchors(0.0, 1.0, 1.0, 0.5)
		else:
			_set_view_anchors(0.5, 1.0, 1.0, 0.0)

func _update_3_player_splitscreen_view(horizontal: bool) -> void:
	match local_id:
		0:
			if horizontal:
				_set_view_anchors(0.0, 1.0, 0.5, 0.0)
			else:
				_set_view_anchors(0.0, 0.5, 1.0, 0.0)
		1:
			if horizontal:
				_set_view_anchors(0.0, 0.5, 1.0, 0.5)
			else:
				_set_view_anchors(0.5, 1.0, 0.5, 0.0)
		2: _set_view_anchors(0.5, 1.0, 1.0, 0.5)

func _update_4_player_splitscreen_view() -> void:
	match local_id:
		0: _set_view_anchors(0.0, 0.5, 0.5, 0.0)
		1: _set_view_anchors(0.5, 1.0, 0.5, 0.0)
		2: _set_view_anchors(0.0, 0.5, 1.0, 0.5)
		3: _set_view_anchors(0.5, 1.0, 1.0, 0.5)

# ////////////////////////////////////////////////////////////////////////////////////////////////
# CAMERA
func _init_camera_rig() -> void:
	camera_rig.perspective = perspective
	
	if is_instance_valid(character):
		if perspective == Perspective.FPS:
			camera_rig.anchor_node = character.get_eye_target()
		else:
			camera_rig.anchor_node = character.camera_socket
		
		camera_rig.connect_animations(character)
	
	camera_rig.make_current()
	camera_rig.zoom = 2.675
	
	if perspective == Perspective.FPS:
		camera_rig.look_bounds.y = 89.0
		camera_rig.anchor_offset.y = 0.0
		camera_rig.spring_arm_3d.position.x = 0.0
	else:
		camera_rig.look_bounds.y = 60.0
		camera_rig.spring_arm_3d.position.x = 0.5
	
	for i in 4:
		if i == local_id: continue
		camera_rig.camera_3d.cull_mask &= ~(1 << (15 + i))

func set_camera_rig(_camera_rig: CameraRig) -> void:
	camera_rig = _camera_rig
	_init_camera_rig()

func spawn_camera_rig() -> void:
	splitscreen_view = SPLITSCREEN_VIEW_SCN.instantiate()
	splitscreen_view.set_multiplayer_authority(get_multiplayer_authority())
	splitscreen_view.hide()
	camera_view_layer.add_child(splitscreen_view)
	
	shader_view = SHADER_VIEW_SCN.instantiate()
	shader_view.set_multiplayer_authority(get_multiplayer_authority())
	shader_view_layer.add_child(shader_view)
	
	camera_rig = CAMERA_RIG.instantiate()
	camera_rig.set_multiplayer_authority(get_multiplayer_authority())
	#splitscreen_view.sub_viewport.add_child(camera_rig)
	camera_view_layer.add_child(camera_rig)
	_init_camera_rig()

# ////////////////////////////////////////////////////////////////////////////////////////////////
# INPUT

# ------------------------------------------------------------------------------------------------
# PRIVATE INPUT
static func _assign_key_action_event(player_id: int, action: String, keycode: Key) -> void:
	var input_event_key: InputEventKey = InputEventKey.new()
	input_event_key.keycode = keycode
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_key)

static func _assign_mouse_button_action_event(player_id: int, action: String, button: MouseButton) -> void:
	var input_event_mouse_button: InputEventMouseButton = InputEventMouseButton.new()
	input_event_mouse_button.button_index = button
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_mouse_button)

static func _assign_default_keyboard_controls(_peer_id: int, player_id: int) -> void:
	## Move
	_assign_key_action_event(player_id, "move_left", KEY_A)
	_assign_key_action_event(player_id, "move_right", KEY_D)
	_assign_key_action_event(player_id, "move_back", KEY_S)
	_assign_key_action_event(player_id, "move_forward", KEY_W)
	
	## No look for KBM
	
	## Action inputs
	_assign_mouse_button_action_event(player_id, "primary", MOUSE_BUTTON_LEFT)
	_assign_mouse_button_action_event(player_id, "secondary", MOUSE_BUTTON_RIGHT)
	_assign_key_action_event(player_id, "sprint", KEY_SHIFT)
	_assign_key_action_event(player_id, "item", KEY_Q)
	_assign_key_action_event(player_id, "interact", KEY_E)
	
	## Menu inputs
	_assign_key_action_event(player_id, "start", KEY_ESCAPE)
