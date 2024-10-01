extends Resource
class_name SoundDatabase

enum SoundType {
	SFX_UI,
	SFX_EXPLOSION,
	SFX_FOOTSTEP,
	BGT_WIND,
	BGT_DRONES,
}

@export var ui: Array[AudioStream]
@export var explosion: Array[AudioStream]
@export var footstep: Array[AudioStream]

@export var wind: Array[AudioStream]
@export var drones: Array[AudioStream]

func get_sound(sound: int, sound_type: int) -> AudioStream:
	match sound_type:
		SoundType.SFX_UI: return ui[sound]
		SoundType.SFX_EXPLOSION: return explosion[sound]
		SoundType.SFX_FOOTSTEP: return footstep[sound]
		SoundType.BGT_WIND: return wind[sound]
		SoundType.BGT_DRONES: return drones[sound]
		_: return null
