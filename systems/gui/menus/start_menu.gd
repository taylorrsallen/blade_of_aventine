class_name StartMenu extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const MAIN_MENU: PackedScene = preload("res://systems/gui/menus/main_menu.scn")
const LEVEL_SELECT: PackedScene = preload("res://systems/gui/menus/level_select/level_select_menu.scn")
const START_MENU: PackedScene = preload("res://systems/gui/menus/start_menu.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_resume_pressed() -> void:
	queue_free()

func _on_restart_pressed() -> void:
	Util.main.level.load_from_data(Util.main.level.data)
	queue_free()

func _on_level_select_pressed() -> void:
	var level_select: LevelSelectMenu = LEVEL_SELECT.instantiate()
	level_select.back_menu = START_MENU
	Util.player.menu_view.add_child(level_select)
	queue_free()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_main_menu_pressed() -> void:
	Util.main.level.unload()
	Util.player.menu_view.add_child(MAIN_MENU.instantiate())
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()
