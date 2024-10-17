extends Node
class_name Main

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal game_started()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const PLAYER_CONTROLLER: PackedScene = preload("res://systems/controller/player/player_controller.scn")
const MAIN_MENU: PackedScene = preload("res://systems/gui/menus/main_menu.scn")
const GAME_PROGRESS_DATA_PATH: String = "user://game_progress.tres"

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var level: Level = $Level
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
var spawn_point: Vector3 = Vector3.ZERO
var extra_spawn_points: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var game_progress_data: GameProgressData

@onready var orcus_clouds_volume: CloudsVolume = $OrcusCloudsVolume

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	_load_game_progress_data()
	level.level_beaten.connect(_on_level_beaten)
	
	Util.main = self
	Util.player = PLAYER_CONTROLLER.instantiate()
	add_child(Util.player)
	Util.player.init()
	#Util.player.menu_view.add_child(MAIN_MENU.instantiate())
	
	game_started.emit()
	
	level.load_from_level_id(1)
	
	#var terrain_model: Node3D = level.get_terrain_model_scene(level.LEVEL_DATABASE.database[1])
	#terrain_model.position.y = 0.5
	#terrain_model.position.z = -10.0
	#terrain_model.scale = Vector3.ONE * 0.1
	#add_child(terrain_model)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func save_game_progress_data() -> void:
	ResourceSaver.save(game_progress_data, GAME_PROGRESS_DATA_PATH)

func _load_game_progress_data() -> void:
	if FileAccess.file_exists(GAME_PROGRESS_DATA_PATH):
		game_progress_data = ResourceLoader.load(GAME_PROGRESS_DATA_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	else:
		game_progress_data = GameProgressData.new()
		ResourceSaver.save(game_progress_data, GAME_PROGRESS_DATA_PATH)

func _on_level_beaten(level_id: int) -> void:
	if !game_progress_data.levels_beaten.has(level_id): game_progress_data.levels_beaten.append(level_id)
	ResourceSaver.save(game_progress_data, GAME_PROGRESS_DATA_PATH)

func clear_user_data() -> void:
	game_progress_data = GameProgressData.new()
	ResourceSaver.save(game_progress_data, GAME_PROGRESS_DATA_PATH)
