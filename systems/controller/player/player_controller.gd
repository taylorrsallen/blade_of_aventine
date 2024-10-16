extends Node
class_name PlayerController

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
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

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SPLITSCREEN_VIEW_SCN: PackedScene = preload("res://systems/controller/player/splitscreen_view.scn")
const SHADER_VIEW_SCN: PackedScene = preload("res://systems/controller/player/shader_view.scn")
const CAMERA_RIG: PackedScene = preload("res://systems/camera/camera_rig.scn")
const HUD_GUI: PackedScene = preload("res://systems/gui/hud/hud.scn")

const START_MENU: PackedScene = preload("res://systems/gui/menus/start_menu.scn")

const AS: PickupData = preload("res://resources/pickups/coins/as.res")
var PICKUP: PackedScene = load("res://systems/level/entities/pickup/pickup.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## COMPOSITION
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

## FLAGS
@export var flags: int

## DATA
var local_id: int

## INPUT
var controls_assigned: int = -1
var device_assigned: int = -1

@export var perspective: Perspective: set = _set_perspective

@export var raw_move_input: Vector3
@export var world_move_input: Vector3
@export var desired_facing: Vector3

var previous_cursor_pos: Vector2
@export var cursor_pos: Vector2
@export var cursor_world_entity: Node3D
@export var cursor_world_pos: Vector3

var focus_world_entity: Node3D
var focus_world_pos: Vector3
var can_interact: bool
var focus_range: float = 1.5

@onready var selection_cursor: Node3D = $SelectionCursor
@onready var aventine_highlighter: Node3D = $aventine_highlighter
@onready var craft_billboard: MeshInstance3D = $CraftBillboard
## The thing you are near with nothing in your hands
var focused_interactable: Interactable: set = _set_focused_interactable
## The thing you are looking at with something in your hands
var selection_interactable: Interactable: set = _set_selection_interactable
var selection_position: Vector3

## VIEW
@onready var camera_view_layer: CanvasLayer = $CameraViewLayer
@export var splitscreen_view: SplitscreenView
@onready var shader_view_layer: CanvasLayer = $ShaderViewLayer
@export var shader_view: ShaderView
@onready var hud_view_layer: CanvasLayer = $HUDViewLayer
@onready var hud_view: Control = $HUDViewLayer/HUDView
@onready var menu_view: Control = $HUDViewLayer/MenuView
var hud: HUDGui

@export var camera_rig: CameraRig

## CHARACTER
@export var body_data: CharacterBodyData
@export var character: Character
@export var respawn_cd: float = 7.0
var respawn_timer: float

@export var dance_exp: float = 1.0
@export var dance_exp_cd: float = 0.2
var dance_exp_timer: float

var money_feed_target: Interactable
var money_feed_cd: float = 0.1
var money_feed_timer: float

## GAME DATA
@export var game_resources: GameResources

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_perspective(_perspective: Perspective) -> void:
	if perspective == _perspective: return
	perspective = _perspective
	if is_instance_valid(camera_rig): _init_camera_rig()

func _set_selection_interactable(_selection_interactable: Interactable) -> void:
	if _selection_interactable != selection_interactable:
		if is_instance_valid(selection_interactable): selection_interactable.set_highlighted(false, character, self)
		if is_instance_valid(_selection_interactable): _selection_interactable.set_highlighted(true, character, self)
		selection_interactable = _selection_interactable

func _set_focused_interactable(_focused_interactable: Interactable) -> void:
	if _focused_interactable != focused_interactable:
		if is_instance_valid(focused_interactable): focused_interactable.set_highlighted(false, character, self)
		if is_instance_valid(_focused_interactable): _focused_interactable.set_highlighted(true, character, self)
		focused_interactable = _focused_interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	Util.main.game_started.connect(_on_game_started)
	
	spawn_camera_rig()
	if local_id == 0:
		assign_default_controls(0)
		set_cursor_captured()
		EventBus.bread_lost.connect(_on_bread_lost)

func _physics_process(delta: float) -> void:
	if local_id == 0 && Util.main.level.level_started && !Util.main.level.no_waves && game_resources.bread == 0:
		Util.main.level.unload()
		Util.main.level.load_from_level_id(1)
	
	_update_movement_input()
	
	#if Input.is_action_just_pressed("toggle_perspective_" + str(local_id)):
		#perspective = Perspective.FPS if perspective == Perspective.TPS else Perspective.TPS
	
	if local_id == 0:
		if !get_window().has_focus():
			set_cursor_visible()
		elif menu_view.get_children().is_empty():
			if is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE): set_cursor_captured()
		else:
			set_cursor_visible()
	
		if Input.is_action_just_pressed("start_0"):
			if menu_view.get_children().is_empty():
				menu_view.add_child(START_MENU.instantiate())
			else:
				for child in menu_view.get_children():
					child.go_back()
	
	if is_instance_valid(camera_rig):
		const ZOOM_BOUNDS: Vector2 = Vector2(0.5, 15.0)
		if local_id == 0:
			if Input.is_action_just_released("zoom_in_" + str(local_id)):
				camera_rig.zoom = clampf(camera_rig.zoom - 0.5, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y)
			elif Input.is_action_just_released("zoom_out_" + str(local_id)):
				camera_rig.zoom = clampf(camera_rig.zoom + 0.5, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y)
		else:
			if Input.is_action_pressed("zoom_in_" + str(local_id)):
				camera_rig.zoom = clampf(camera_rig.zoom - 3.0 * delta, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y)
			elif Input.is_action_pressed("zoom_out_" + str(local_id)):
				camera_rig.zoom = clampf(camera_rig.zoom + 3.0 * delta, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y)
		
		if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
			var look_movement: Vector2 = Vector2.ZERO
			if local_id == 0:
				var cursor_movement: Vector2 = (get_viewport().size * 0.5).floor() - get_viewport().get_mouse_position()
				get_viewport().warp_mouse((get_viewport().size * 0.5).floor())
				look_movement += cursor_movement
			
			var gamepad_look_input: Vector2 = Input.get_vector("look_left_" + str(local_id), "look_right_" + str(local_id), "look_down_" + str(local_id), "look_up_" + str(local_id)) * 4.0 * camera_rig.gamepad_look_sensitivity
			gamepad_look_input.x = -gamepad_look_input.x
			look_movement += gamepad_look_input
			
			camera_rig.apply_inputs(raw_move_input, look_movement, delta)
			camera_rig.apply_camera_rotation()
		
	if is_instance_valid(character):
		_update_selection()
		_dance_for_me(delta)
		
		#DebugDraw3D.draw_aabb(AABB(selection_position, Vector3.ONE), Color.ORANGE, delta)
		#DebugDraw3D.draw_line(selection_position, selection_position + Vector3.UP * 5.0, Color.ORANGE, 0.016)
		
		AreaQueryManager.request_area_query(self, character.global_position, focus_range * 2.0, 512)
		
		for pickup_body in AreaQueryManager.query_area(character.global_position, 5.0, 8):
			pickup_body.get_parent().take(character)
		
		_update_character_input(delta)
		_update_money_feed_target(delta)
		_update_hud()
		
		character.face_direction(world_move_input, delta)
	else:
		respawn_timer += delta
		if respawn_timer >= respawn_cd:
			respawn_character()
			respawn_timer = 0.0

func _dance_for_me(delta: float) -> void:
	if !character.grabbed_entity && is_instance_valid(focused_interactable) && focused_interactable is TowerBase && focused_interactable.built:
		character.body.set_dancing(true)
		dance_exp_timer += delta
		if dance_exp_timer >= dance_exp_cd:
			dance_exp_timer -= dance_exp_cd
			focused_interactable.add_experience(dance_exp)
	else:
		character.body.set_dancing(false)

func _update_selection() -> void:
	var selection_out_of_bounds: bool = false
	var show_craft_billboard: bool = false
	var show_highlighter: bool = false
	var show_selection_cursor: bool = false
	
	selection_position = (character.global_position + camera_rig.get_yaw_forward()).floor()
	if Util.main.level.is_global_coord_in_bounds(selection_position):
		selection_position.y = Util.main.level.get_placement_height_at_global_coord(selection_position)
	else:
		selection_out_of_bounds = true
		selection_position.y = 0.0
	
	if is_instance_valid(character.grabbed_entity):
		selection_interactable = Util.main.level.get_interactable_from_global_coord(selection_position)
		
		if is_instance_valid(focused_interactable) && focused_interactable is ShopItemDisplay && character.grabbed_entity is BlockPile:
			show_highlighter = true
			aventine_highlighter.global_position = focused_interactable.global_position
		else:
			if is_instance_valid(selection_interactable):
				show_highlighter = true
				aventine_highlighter.global_position = selection_position + Vector3(0.5, 0.0, 0.5)
			else:
				show_selection_cursor = true
				selection_cursor.position = selection_position + Vector3(0.5, 0.0, 0.5)
	else:
		if is_instance_valid(focused_interactable):
			show_highlighter = true
			aventine_highlighter.global_position = focused_interactable.global_position
			if focused_interactable is BlockPile && focused_interactable.valid_recipe:
				show_craft_billboard = true
				craft_billboard.position = focused_interactable.global_position + Vector3.UP * (focused_interactable.pile_height + 0.5)
	
	craft_billboard.visible = show_craft_billboard
	aventine_highlighter.visible = show_highlighter
	if !selection_out_of_bounds:
		selection_cursor.visible = show_selection_cursor
	else:
		selection_cursor.visible = false

func _update_money_feed_target(delta: float) -> void:
	if !is_instance_valid(money_feed_target): return
	if focused_interactable == money_feed_target && Input.is_action_pressed("interact_" + str(local_id)):
		money_feed_timer = min(money_feed_timer + delta, money_feed_cd)
		if game_resources.coins > 0 && money_feed_timer == money_feed_cd:
			if money_feed_target is TowerBase:
				if money_feed_target.level == money_feed_target.type_data.level_blueprints.size() - 1:
					money_feed_target = null
					return
				money_feed_target.add_experience(0.9)
				money_feed_target.money_fed += 1.0
			game_resources.coins -= 1
			var pickup: Pickup = PICKUP.instantiate()
			pickup.position = character.global_position
			pickup.pickup_data = AS
			Util.main.level.add_pickup(pickup)
			pickup.take(money_feed_target)
	else:
		money_feed_target = null

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func is_flag_on(flag: PlayerControllerFlag) -> bool: return Util.is_flag_on(flags, flag)
func set_flag_on(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_on(flags, flag)
func set_flag_off(flag: PlayerControllerFlag) -> void: flags = Util.set_flag_off(flags, flag)
func set_flag(flag: PlayerControllerFlag, active: bool) -> void: flags = Util.set_flag(flags, flag, active)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## For removing non-host local players from the game
func remove() -> void:
	if local_id == 0: return

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_area_query(results: Array[PhysicsBody3D]) -> void:
	if !is_instance_valid(character): return
	
	var interactables: Array[Interactable] = []
	for result in results:
		if result is InteractableCollider:
			interactables.append(result.get_parent())
	
	## There are one time events to do with highlighting that occur when focused_interactable is set, which is why we use a temp variable here
	var new_focused_interactable: Interactable = null
	var closest_distance: float = 100.0
	for interactable in interactables:
		#DebugDraw3D.draw_line(interactable.global_position, interactable.global_position + Vector3.UP * 5.0, Color.RED, 0.016)
		var distance: float = Vector3(character.global_position.x, 0.0, character.global_position.z).distance_to(Vector3(interactable.global_position.x, 0.0, interactable.global_position.z))
		if distance > focus_range: continue
		if distance < closest_distance:
			new_focused_interactable = interactable
			closest_distance = distance
	
	focused_interactable = new_focused_interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_hud() -> void:
	if !is_instance_valid(hud): return
	if Input.is_action_pressed("recipes_" + str(local_id)):
		hud.recipes.show()
	else:
		hud.recipes.hide()
	
	if local_id == 0:
		if !game_resources: return
		hud.coins_label.text = str(game_resources.coins)
		hud.bread_label.text = str(game_resources.bread)
	else:
		if !game_resources || !Util.player.game_resources: return
		hud.coins_label.text = str(game_resources.coins)
		hud.bread_label.text = str(Util.player.game_resources.bread)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_character_input(_delta: float) -> void:
	character.look_basis = camera_rig.rotation_target.basis
	character.look_direction = camera_rig.get_camera_forward()
	character.move_input = raw_move_input
	character.world_move_input = world_move_input
	character.desired_facing = desired_facing
	character.look_scalar = camera_rig.get_look_up_down_scalar()
	
	if !is_flag_on(PlayerControllerFlag.CURSOR_VISIBLE):
		if Input.is_action_just_pressed("primary_" + str(local_id)): _primary()
		if Input.is_action_just_pressed("secondary_" + str(local_id)): _secondary()
		if Input.is_action_just_pressed("interact_" + str(local_id)): _interact()
		
		#if Input.is_action_just_pressed("item_" + str(local_id)): character.use_item()
	
	if Input.is_action_pressed("sprint_" + str(local_id)): character.set_sprinting(true)
	if Input.is_action_just_released("sprint_" + str(local_id)): character.set_sprinting(false)
	
	if character.current_speed > character.jog_speed && character.move_input != Vector3.ZERO:
		camera_rig.fov_mod = (character.current_speed - character.jog_speed) * 1.5
	else:
		camera_rig.fov_mod = 0.0

func _primary() -> void:
	if !is_instance_valid(character.grabbed_entity):
		if is_instance_valid(focused_interactable):
			if focused_interactable is BlockPile:
				SoundManager.play_3d_sfx(3, SoundDatabase.SoundType.SFX_FOLEY, character.global_position + Vector3.UP * 0.5)
				character.grab_entity(focused_interactable.take_block())
			elif focused_interactable is TowerBase:
				if focused_interactable.built && focused_interactable.interactable_data.liftable:
					SoundManager.play_3d_sfx(3, SoundDatabase.SoundType.SFX_FOLEY, character.global_position + Vector3.UP * 0.5)
					character.grab_entity(focused_interactable)
			elif focused_interactable.interactable_data.liftable:
				character.grab_entity(focused_interactable)
			else:
				focused_interactable.interact(character, self)
	else:
		_place_grabbed_entity()

func _secondary() -> void:
	if is_instance_valid(character.grabbed_entity):
		if character.grabbed_entity.interactable_data.throwable:
			var entity_to_throw: Interactable = character.drop_grabbed_entity()
			entity_to_throw.velocity = -character.body_center_pivot.global_basis.z * 10.0 + Vector3.UP * 3.0
			entity_to_throw.set_tumbling(true)
			entity_to_throw.collider_that_threw_me = character
			return
	elif character.try_attack():
		var check_for_characters_global_coord: Vector3 = character.global_position - character.body_container.global_basis.z * 0.5 + Vector3.UP * character.body_data.height * 0.5
		var other_characters: Array[PhysicsBody3D] = AreaQueryManager.query_area(check_for_characters_global_coord, 0.8, 2, [character])
		
		var closest_character: Character = null
		var closest_distance: float = 100.0
		for other_character in other_characters:
			if !is_instance_valid(character): continue
			var distance: float = character.global_position.distance_to(other_character.global_position)
			if distance < closest_distance:
				closest_character = other_character
				closest_distance = distance
		
		if is_instance_valid(closest_character):
			SoundManager.play_pitched_3d_sfx(29 + randi_range(0, 1), SoundDatabase.SoundType.SFX_FOLEY, character.global_position + Vector3.UP * 0.5, 0.9, 1.1, -10.0)
			
			var damage_data: DamageData = DamageData.new()
			damage_data.damage_strength = 0.5
			closest_character.damage(damage_data, character)
		
		if !is_instance_valid(focused_interactable): return
		if focused_interactable is TowerBase && focused_interactable.built:
			focused_interactable.deal_scepter_damage()
		elif focused_interactable.has_method("deal_scepter_damage"):
			focused_interactable.deal_scepter_damage()

func _interact() -> void:
	if is_instance_valid(character.grabbed_entity): return
	if !is_instance_valid(focused_interactable): return
	if focused_interactable is BlockPile:
		if focused_interactable.try_craft():
			character.body.special()
			SoundManager.play_pitched_3d_sfx(27, SoundDatabase.SoundType.SFX_FOLEY, character.global_position + Vector3.UP * 0.5)
	elif focused_interactable is TowerBase:
		money_feed_target = focused_interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _place_grabbed_entity() -> void:
	var shop_item_display_focused: bool
	if is_instance_valid(focused_interactable):
		if focused_interactable is ShopItemDisplay:
			shop_item_display_focused = true
			if character.grabbed_entity is BlockPile && focused_interactable.will_buy(character.grabbed_entity):
				var grabbed_block_pile: BlockPile = character.drop_grabbed_entity()
				focused_interactable.give_coins_for_block(grabbed_block_pile.blocks[0], character)
				grabbed_block_pile.queue_free()
	
	if !shop_item_display_focused:
		if is_instance_valid(selection_interactable):
			if selection_interactable is BlockPile && character.grabbed_entity is BlockPile:
				var grabbed_block_pile: BlockPile = character.drop_grabbed_entity()
				selection_interactable.add_block_pile(grabbed_block_pile)
		elif Util.main.level.is_global_coord_in_bounds(selection_position) && !Util.main.level.get_terrain_tile_at_global_coord(selection_position).blocks_entity_placement:
			var place_at_global_coord: Vector3 = selection_position + Vector3(0.5, 0.0, 0.5)
			var entity: Interactable = character.drop_grabbed_entity()
			Util.main.level.place_interactable_at_global_coord(place_at_global_coord, entity)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_movement_input() -> void:
	desired_facing = camera_rig.get_yaw_forward()
	
	var raw_horizontal_move_input: Vector2 = Input.get_vector("move_left_" + str(local_id), "move_right_" + str(local_id), "move_forward_" + str(local_id), "move_back_" + str(local_id)).normalized()
	raw_move_input.x = raw_horizontal_move_input.x
	raw_move_input.z = raw_horizontal_move_input.y
	
	world_move_input = camera_rig.get_yaw_local_vector3(raw_move_input)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
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
	get_viewport().warp_mouse(get_viewport().size * 0.5)
	set_flag_off(PlayerControllerFlag.CURSOR_VISIBLE)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# CHARACTER
func respawn_character() -> void:
	if is_instance_valid(character): character.queue_free()
	
	const CHARACTER_SCN: PackedScene = preload("res://systems/character/character.scn")
	character = CHARACTER_SCN.instantiate()
	
	character.body_data = body_data
	
	if local_id == 0:
		character.position = Util.main.spawn_point
	else:
		character.position = Util.main.extra_spawn_points[local_id - 1]
	
	character.collision_layer = 34
	character.team = 0
	character.pickup_received.connect(_on_pickup_received)
	character.entered_gateway.connect(_on_entered_gateway)
	character.killed.connect(_on_character_killed)
	
	add_child(character)
	_init_camera_rig()

func _on_character_killed() -> void:
	print("You died.")
	var source_position: Vector3 = character.global_position
	var coins_to_spawn: Array[PickupData] = CoinSpawner.get_coins_for_amount(game_resources.coins)
	game_resources.coins = 0
	_update_hud()
	for coin in coins_to_spawn:
		var pickup: Pickup = PICKUP.instantiate()
		pickup.pickup_data = coin
		pickup.position = source_position
		Util.main.level.add_pickup(pickup)
	camera_rig.anchor_position = character.global_position + Vector3.UP

func _on_pickup_received(pickup: PickupData) -> void:
	if pickup.metadata.has("coins"): game_resources.coins += pickup.metadata["coins"]
	if pickup.metadata.has("bread"):
		if is_instance_valid(Util.main.level.faction_bread_piles[0]):
			Util.main.level.faction_bread_piles[0].bread_count += pickup.metadata["bread"]

func _on_entered_gateway(gateway_data: GatewayData) -> void:
	print("Entered gateway with destination %s" % gateway_data.destination_level_id)
	Util.main.level.load_from_level_id(gateway_data.destination_level_id)

func _on_bread_lost() -> void:
	if !game_resources: return
	game_resources.bread -= 1

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# GAME START
func _on_game_started() -> void:
	game_resources = GameResources.new()
	if !Util.main.level.faction_bread_piles.is_empty() && is_instance_valid(Util.main.level.faction_bread_piles[0]): game_resources.bread = Util.main.level.faction_bread_piles[0].bread_count
	respawn_character()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
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

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
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
	#camera_rig.zoom = 20.0
	#camera_rig.zoom = 2.675
	
	camera_rig.look_bounds.y = 60.0
	camera_rig.spring_arm_3d.position.x = 0.0
	camera_rig.anchor_offset.y = 0.5
	
	for i in 4:
		if i == local_id: continue
		camera_rig.camera_3d.cull_mask &= ~(1 << (15 + i))
	
	camera_rig.anchor_position = Util.main.spawn_point + Vector3.UP

func set_camera_rig(_camera_rig: CameraRig) -> void:
	camera_rig = _camera_rig
	_init_camera_rig()

func spawn_camera_rig() -> void:
	splitscreen_view = SPLITSCREEN_VIEW_SCN.instantiate()
	
	# TOGGLE
	camera_view_layer.add_child(splitscreen_view)
	
	shader_view = SHADER_VIEW_SCN.instantiate()
	shader_view_layer.add_child(shader_view)
	
	camera_rig = CAMERA_RIG.instantiate()
	
	# TOGGLE
	splitscreen_view.sub_viewport.add_child(camera_rig)
	
	# TOGGLE
	#camera_view_layer.add_child(camera_rig)
	
	_init_camera_rig()
	
	if is_instance_valid(hud): hud.queue_free()
	hud = HUD_GUI.instantiate()
	Util.main.level.wave_progress_changed.connect(hud._on_wave_progress_changed)
	Util.main.level.active_wave_icons_changed.connect(hud._on_active_wave_icons_changed)
	Util.main.level.incoming_wave_icons_changed.connect(hud._on_incoming_wave_icons_changed)
	Util.main.level.next_wave_icons_changed.connect(hud._on_next_wave_icons_changed)
	hud_view.add_child(hud)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
# INPUT
func assign_default_controls(control_type: int, device: int = 0) -> void:
	PlayerController.assign_default_controls_by_id(local_id, control_type, device)
	controls_assigned = control_type
	device_assigned = device

static func assign_default_controls_by_id(player_id: int, control_type: int, device: int = 0) -> void:
	match control_type:
		0: _assign_default_keyboard_controls(player_id)
		1: _assign_default_gamepad_sony_controls(player_id, device)
		2: _assign_default_gamepad_nintendo_controls(player_id, device)
		3: _assign_default_gamepad_xbox_controls(player_id, device)

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

static func _assign_gamepad_button_action_event(player_id: int, device: int, action: String, button: JoyButton) -> void:
	var input_event_joypad_button: InputEventJoypadButton = InputEventJoypadButton.new()
	input_event_joypad_button.button_index = button
	input_event_joypad_button.device = device
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_joypad_button)

static func _assign_gamepad_motion_action_event(player_id: int, device: int, action: String, axis: JoyAxis, value: float) -> void:
	var input_event_joypad_motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	input_event_joypad_motion.axis = axis
	input_event_joypad_motion.axis_value = value
	input_event_joypad_motion.device = device
	InputMap.action_erase_events(action + "_" + str(player_id))
	InputMap.action_add_event(action + "_" + str(player_id), input_event_joypad_motion)

static func _assign_default_keyboard_controls(player_id: int) -> void:
	## Move
	_assign_key_action_event(player_id, "move_left", KEY_A)
	_assign_key_action_event(player_id, "move_right", KEY_D)
	_assign_key_action_event(player_id, "move_back", KEY_S)
	_assign_key_action_event(player_id, "move_forward", KEY_W)
	
	## No look for KBM
	
	## Action inputs
	_assign_mouse_button_action_event(player_id, "primary", MOUSE_BUTTON_LEFT)
	_assign_mouse_button_action_event(player_id, "secondary", MOUSE_BUTTON_RIGHT)
	_assign_mouse_button_action_event(player_id, "zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_assign_mouse_button_action_event(player_id, "zoom_out", MOUSE_BUTTON_WHEEL_DOWN)
	_assign_key_action_event(player_id, "sprint", KEY_SHIFT)
	_assign_key_action_event(player_id, "interact", KEY_E)
	_assign_key_action_event(player_id, "recipes", KEY_TAB)
	
	## Menu inputs
	_assign_key_action_event(player_id, "start", KEY_ESCAPE)


static func _assign_default_gamepad_axis_controls(player_id: int, device: int) -> void:
	_assign_gamepad_motion_action_event(player_id, device, "move_left", JOY_AXIS_LEFT_X, -1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_right", JOY_AXIS_LEFT_X, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_back", JOY_AXIS_LEFT_Y, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "move_forward", JOY_AXIS_LEFT_Y, -1.0)
	
	_assign_gamepad_motion_action_event(player_id, device, "look_left", JOY_AXIS_RIGHT_X, -1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_right", JOY_AXIS_RIGHT_X, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_assign_gamepad_motion_action_event(player_id, device, "look_up", JOY_AXIS_RIGHT_Y, -1.0)

static func _assign_default_gamepad_common_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_axis_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "zoom_in", JOY_BUTTON_DPAD_UP)
	_assign_gamepad_button_action_event(player_id, device, "zoom_out", JOY_BUTTON_DPAD_DOWN)
	#if player_id == 0: _assign_gamepad_button_action_event(player_id, device, "start", JOY_BUTTON_START)

static func _assign_default_gamepad_sony_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_A) # CROSS
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_B) # CIRCLE
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_X) # SQUARE
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)
	
	#_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_Y) # TRIANGLE

static func _assign_default_gamepad_nintendo_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_X) # A
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_A) # B
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_Y) # X
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)

static func _assign_default_gamepad_xbox_controls(player_id: int, device: int) -> void:
	_assign_default_gamepad_common_controls(player_id, device)
	
	_assign_gamepad_button_action_event(player_id, device, "primary", JOY_BUTTON_A) # CROSS
	_assign_gamepad_button_action_event(player_id, device, "secondary", JOY_BUTTON_B) # CIRCLE
	_assign_gamepad_button_action_event(player_id, device, "sprint", JOY_BUTTON_RIGHT_SHOULDER)
	_assign_gamepad_button_action_event(player_id, device, "interact", JOY_BUTTON_X) # SQUARE
	_assign_gamepad_button_action_event(player_id, device, "recipes", JOY_BUTTON_LEFT_SHOULDER)
