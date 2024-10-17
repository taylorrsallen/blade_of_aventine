class_name StartMenu extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const MAIN_MENU: PackedScene = preload("res://systems/gui/menus/main_menu.scn")
const LEVEL_SELECT: PackedScene = preload("res://systems/gui/menus/level_select/level_select_menu.scn")
const START_MENU: PackedScene = preload("res://systems/gui/menus/start_menu.scn")
var SETTINGS_MENU: PackedScene = load("res://systems/gui/menus/settings/settings_menu.scn")
var PLAYERS_MENU: PackedScene = load("res://systems/gui/menus/players/players_menu.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var start_panel_container: PanelContainer = $StartPanelContainer
@onready var clear_user_data_confirmation: PanelContainer = $StartPanelContainer/MarginContainer/CanvasLayer/ClearUserDataConfirmation

@onready var orcus: TextureButtonWithText = $StartPanelContainer/MarginContainer/CanvasLayer/Buttons/ButtonVBoxContainer/Orcus
@onready var fake_button_box: Control = $StartPanelContainer/MarginContainer/FakeButtonBox
@onready var buttons: Control = $StartPanelContainer/MarginContainer/CanvasLayer/Buttons

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	if Util.main.level.data_id == 1: orcus.disabled = true
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_resume_pressed() -> void:
	queue_free()

func _on_restart_pressed() -> void:
	Util.main.level.load_from_level_id(Util.main.level.data_id)
	queue_free()

func _on_level_select_pressed() -> void:
	var level_select: LevelSelectMenu = LEVEL_SELECT.instantiate()
	level_select.back_menu = START_MENU
	Util.player.menu_view.add_child(level_select)
	queue_free()

func _on_players_pressed() -> void:
	var players: PlayersMenu = PLAYERS_MENU.instantiate()
	Util.player.menu_view.add_child(players)
	queue_free()

func _on_settings_pressed() -> void:
	var settings: SettingsMenu = SETTINGS_MENU.instantiate()
	Util.player.menu_view.add_child(settings)
	queue_free()

func _on_orcus_pressed() -> void:
	Util.main.level.load_from_level_id(1)
	queue_free()

func _on_clear_user_data_pressed() -> void:
	start_panel_container.hide()
	buttons.hide()
	clear_user_data_confirmation.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_no_pressed() -> void:
	start_panel_container.show()
	buttons.show()
	clear_user_data_confirmation.hide()

func _on_clearuserdata_pressed() -> void:
	start_panel_container.show()
	buttons.show()
	clear_user_data_confirmation.hide()
	Util.main.clear_user_data()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_viewport_size_changed() -> void:
	start_panel_container.global_position = get_viewport().size * 0.5 - start_panel_container.size * 0.5 * start_panel_container.scale
	buttons.global_position = start_panel_container.global_position
