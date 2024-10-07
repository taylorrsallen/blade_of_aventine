extends Node
class_name Main

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal game_started()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const PLAYER_CONTROLLER: PackedScene = preload("res://systems/controller/player/player_controller.scn")
const MAIN_MENU: PackedScene = preload("res://systems/gui/menus/main_menu.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var spawn_point: Vector3 = Vector3.ZERO
@onready var level: Level = $Level

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	Util.main = self
	Util.player = PLAYER_CONTROLLER.instantiate()
	add_child(Util.player)
	Util.player.init()
	Util.player.menu_view.add_child(MAIN_MENU.instantiate())
	
	game_started.emit()
	
	#var terrain_model: Node3D = level.get_terrain_model_scene(level.LEVEL_DATABASE.database[1])
	#terrain_model.position.y = 0.5
	#terrain_model.position.z = -10.0
	#terrain_model.scale = Vector3.ONE * 0.1
	#add_child(terrain_model)
