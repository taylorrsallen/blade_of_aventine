class_name SpecialNPCData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum SpawnAnimation {
	NONE,
	RISE_FROM_GROUND,
}

enum DialogueFinishedAction {
	NONE,
	DISAPPEAR,
	SEND_TO_LEVEL,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_category("Core")
@export var scene: PackedScene
@export var speaker_data: DialogueSpeakerData
@export var height: float = 1.0
@export var collision: bool = true
@export var hit_reaction: DialogueFinishedAction

@export_category("Spawn")
@export var spawn_animation: SpawnAnimation
@export var spawn_animation_time: float
@export var spawn_sound: SoundReferenceData

@export_category("Dialogue")
@export var dialogue_spawn_delay: float
@export var dialogue_interact_sound: SoundPoolData
@export var dialogue_finished_action: DialogueFinishedAction
@export var dialogue_finished_sound: SoundPoolData
@export var level_id_to_send_player_to: int = -10
@export var dialogue_data_override: DialogueData
