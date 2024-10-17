class_name LevelSelectMenu extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const LEVEL_SELECT_BUTTON: PackedScene = preload("res://systems/gui/menus/level_select/level_select_menu_button.scn")
const LEVEL: PackedScene = preload("res://systems/level/level.scn")

var LEVEL_DATABASE: LevelDatabase = load("res://resources/levels/level_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var levels_h_box_container: VBoxContainer = $CanvasLayer/Control/LevelsHBoxContainer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	for i in LEVEL_DATABASE.database.size():
		var level_data: LevelData = LEVEL_DATABASE.database[i]
		if level_data.hidden: continue
		if level_data.required_level_id_to_be_played != -1 && !Util.main.game_progress_data.levels_beaten.has(level_data.required_level_id_to_be_played): continue
		
		var button: LevelSelectMenuButton = LEVEL_SELECT_BUTTON.instantiate()
		button.text = level_data.name
		button.level_id = i
		button.selected.connect(_on_level_selected)
		levels_h_box_container.add_child(button)

func _on_level_selected(level_id: int) -> void:
	Util.main.level.load_from_level_id(level_id)
	Util.player.set_cursor_captured()
	queue_free()

func _on_back_pressed() -> void:
	go_back()
