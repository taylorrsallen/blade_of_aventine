class_name LevelData extends Resource

@export var name: String
@export var layout_texture: Texture2D
@export var faction_game_datas: Array[FactionGameData]
@export var waves: Array[LevelWaveData]
@export var hidden: bool
@export var music_id: int
@export var boss_music_id: int
@export var required_level_id_to_be_played: int = -1
