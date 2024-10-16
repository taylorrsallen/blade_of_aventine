class_name PlayerControlPanel extends PanelContainer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const PLAYER_CONTROLLER: PackedScene = preload("res://systems/controller/player/player_controller.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var player_local_id: int: set = _set_player_local_id

@onready var player_label: TextureButtonWithText = $MarginContainer/VBoxContainer/HBoxContainer2/PlayerLabel
@onready var controls_label: TextureButtonWithText = $MarginContainer/VBoxContainer/HBoxContainer2/ControlsLabel
@onready var add_player: TextureButtonWithText = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AddPlayer
@onready var remove_player: TextureButtonWithText = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/RemovePlayer
@onready var assign_kbm: TextureButtonWithText = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignKBM

var device_id_to_assign: int

var readied: bool

var ASSIGN_DEVICE_BUTTONS: Array[TextureButtonWithText]
var ASSIGN_CONTROL_BUTTONS: Array[TextureButtonWithText]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_player_local_id(_player_local_id: int) -> void:
	player_local_id = _player_local_id
	if !readied: return
	player_label.text = "Player %s" % (player_local_id + 1)
	if player_local_id == 0:
		player_label.disabled = true
		add_player.hide()
		for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.show()
		assign_kbm.show()
		_update_controls_assigned_label(Util.player.controls_assigned, Util.player.device_assigned)
	else:
		var player_controller: PlayerController = Util.extra_players[player_local_id - 1]
		if !is_instance_valid(player_controller): return
		add_player.hide()
		remove_player.show()
		for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.show()
		_update_controls_assigned_label(player_controller.controls_assigned, player_controller.device_assigned)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	ASSIGN_DEVICE_BUTTONS = [
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignDevice1,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignDevice2,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignDevice3,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignDevice4,
	]
	
	ASSIGN_CONTROL_BUTTONS = [
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignSony,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignNintendo,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/AssignXbox,
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Cancel,
	]
	
	readied = true
	player_local_id = player_local_id

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_controls_assigned_label(controls_assigned: int, device_assigned: int) -> void:
	match controls_assigned:
		-1: controls_label.text = "No Controls"
		0: controls_label.text = "KBM"
		1: controls_label.text = "Sony %s" % (device_assigned + 1)
		2: controls_label.text = "Nintendo %s" % (device_assigned + 1)
		3: controls_label.text = "Xbox %s" % (device_assigned + 1)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_add_player_pressed() -> void:
	var player_controller: PlayerController = PLAYER_CONTROLLER.instantiate()
	player_controller.local_id = player_local_id
	Util.main.add_child(player_controller)
	player_controller.init()
	player_controller._on_game_started()
	Util.extra_players[player_local_id - 1] = player_controller
	
	add_player.hide()
	remove_player.show()
	for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.show()
	if player_local_id == 0: assign_kbm.show()
	
	_update_splitscreen()

func _on_remove_player_pressed() -> void:
	if player_local_id == 0: return
	
	add_player.show()
	remove_player.hide()
	for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.hide()
	assign_kbm.hide()
	for assign_control_button in ASSIGN_CONTROL_BUTTONS: assign_control_button.hide()
	
	var player_controller: PlayerController = Util.extra_players[player_local_id - 1]
	if !is_instance_valid(player_controller): return
	player_controller.queue_free()
	Util.extra_players[player_local_id - 1] = null
	
	controls_label.text = "No Controls"
	
	_update_splitscreen()

func _update_splitscreen() -> void:
	var player_count: int = 1
	for extra_player in Util.extra_players: if is_instance_valid(extra_player): player_count += 1
	
	Util.player.update_splitscreen_view(player_count)
	for extra_player in Util.extra_players: if is_instance_valid(extra_player): extra_player.update_splitscreen_view(player_count)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_assign_device_1_pressed() -> void: _try_assign_controls_to_device_id(0)
func _on_assign_device_2_pressed() -> void: _try_assign_controls_to_device_id(1)
func _on_assign_device_3_pressed() -> void: _try_assign_controls_to_device_id(2)
func _on_assign_device_4_pressed() -> void: _try_assign_controls_to_device_id(3)

func _try_assign_controls_to_device_id(device_id: int) -> void:
	device_id_to_assign = device_id
	for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.hide()
	assign_kbm.hide()
	for assign_control_button in ASSIGN_CONTROL_BUTTONS: assign_control_button.show()
	controls_label.text = "Assign Device %s" % device_id

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_assign_sony_pressed() -> void: _assign_control_type(1)
func _on_assign_nintendo_pressed() -> void: _assign_control_type(2)
func _on_assign_xbox_pressed() -> void: _assign_control_type(3)

func _on_cancel_pressed() -> void:
	for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.show()
	for assign_control_button in ASSIGN_CONTROL_BUTTONS: assign_control_button.hide()
	
	var player_controller: PlayerController
	if player_local_id == 0:
		player_controller = Util.player
		assign_kbm.show()
	else:
		player_controller = Util.extra_players[player_local_id - 1]
	
	if is_instance_valid(player_controller):
		_update_controls_assigned_label(player_controller.controls_assigned, player_controller.device_assigned)
	else:
		controls_label.text = "No Controls"

func _assign_control_type(control_type: int) -> void:
	if player_local_id == 0:
		var player_controller: PlayerController = Util.player
		player_controller.assign_default_controls(control_type, device_id_to_assign)
		_update_controls_assigned_label(player_controller.controls_assigned, player_controller.device_assigned)
		assign_kbm.show()
	else:
		var player_controller: PlayerController = Util.extra_players[player_local_id - 1]
		if !is_instance_valid(player_controller): return
		player_controller.assign_default_controls(control_type, device_id_to_assign)
		_update_controls_assigned_label(player_controller.controls_assigned, player_controller.device_assigned)
	
	for assign_device_button in ASSIGN_DEVICE_BUTTONS: assign_device_button.show()
	for assign_control_button in ASSIGN_CONTROL_BUTTONS: assign_control_button.hide()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_assign_kbm_pressed() -> void:
	if !player_local_id == 0: return
	Util.player.assign_default_controls(0)
	_update_controls_assigned_label(Util.player.controls_assigned, Util.player.device_assigned)
	
