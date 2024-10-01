extends Node
class_name Main

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal game_started()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const PLAYER_CONTROLLER: PackedScene = preload("res://systems/controller/player/player_controller.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var spawn_point: Vector3 = Vector3.ZERO
@onready var level: Level = $Level

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	Util.main = self
	Util.player = PLAYER_CONTROLLER.instantiate()
	add_child(Util.player)
	Util.player.init()
	
	game_started.emit()
