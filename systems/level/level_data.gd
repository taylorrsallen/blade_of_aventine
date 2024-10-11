class_name LevelData extends Resource

@export_category("Core")
@export var name: String
@export var layout_texture: Texture2D
@export var faction_game_datas: Array[FactionGameData]
@export var waves: Array[LevelWaveData]

@export_category("Access")
@export var hidden: bool
@export var required_level_id_to_be_played: int = -1

@export_category("Music")
@export var music: SoundReferenceData
@export var boss_music: SoundReferenceData
@export var victory_music: SoundReferenceData

@export_category("Victory")
@export var victory_dialogue: DialogueData
@export var next_level_id: int = -1
