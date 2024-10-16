class_name LevelData extends Resource

@export_category("Core")
@export var name: String
@export var layout_texture: Texture2D
@export var faction_game_datas: Array[FactionGameData]
@export var waves: Array[LevelWaveData]

@export_category("Access")
@export var hidden: bool
@export var required_level_id_to_be_played: int = -1
@export var wait_for_first_tower_before_starting_waves: bool

@export_category("Music")
@export var music: SoundReferenceData
@export var boss_music: SoundReferenceData
@export var victory_music: SoundReferenceData

@export_category("Ambient Sounds")
@export var ambient_tracks: SoundPoolData

@export_category("Victory")
@export var victory_dialogue: DialogueData
@export var next_level_id: int = -1

@export_category("Scene")
@export var sun_color: Color = Color8(210, 200, 167)
@export var sun_brightness: float = 1.0
@export var sun_rotation: Vector3 = Vector3(-36.0, 50.0, -82.0)
@export var world_environment: Environment
