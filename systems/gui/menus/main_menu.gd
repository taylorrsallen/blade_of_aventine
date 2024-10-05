class_name MainMenu extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var LEVEL_SELECT: PackedScene = load("res://systems/gui/menus/level_select/level_select_menu.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_play_pressed() -> void:
	Util.player.menu_view.add_child(LEVEL_SELECT.instantiate())
	queue_free()

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
