class_name PlayersMenu extends MenuBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var grid_container: GridContainer = $CanvasLayer/GridContainer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_viewport_size_changed() -> void:
	if get_viewport().size.x < 1600.0:
		grid_container.scale = Vector2.ONE
		grid_container.size = get_viewport().size
	else:
		grid_container.scale = Vector2.ONE * 1.5
		grid_container.size = get_viewport().size * 0.6666666

func _on_back_pressed() -> void:
	go_back()
