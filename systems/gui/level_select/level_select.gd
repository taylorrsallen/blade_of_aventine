class_name LevelSelect extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const LEVEL_SELECT_BUTTON: PackedScene = preload("res://systems/gui/level_select/level_select_button.scn")
const LEVEL: PackedScene = preload("res://systems/level/level.scn")

const LEVEL_DATABASE: LevelDatabase = preload("res://resources/levels/level_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var levels_h_box_container: HBoxContainer = $LevelsHBoxContainer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	for i in LEVEL_DATABASE.database.size():
		var button: LevelSelectButton = LEVEL_SELECT_BUTTON.instantiate()
		button.text = LEVEL_DATABASE.database[i].name
		button.level_id = i
		levels_h_box_container.add_child(button)

func _on_level_selected(level_id: int) -> void:
	Util.main.level.load_from_data(LEVEL_DATABASE.database[level_id])

func _on_back_pressed() -> void:
	go_back()
