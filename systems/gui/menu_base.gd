class_name MenuBase extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var back_closes: bool
@export var back_menu: PackedScene

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func go_back() -> void:
	if back_menu:
		back_menu.instantiate()
		Util.player.hud_view.add_child(back_menu.instantiate())
		queue_free()
	elif back_closes:
		queue_free()
