class_name RandomNoises extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var random_sound_pool: SoundPoolData
@export var random_sound_cd: float = 10.0
var random_sound_timer: float = randf_range(0.0, random_sound_cd)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	random_sound_timer += delta * (randf() + 0.5)
	if random_sound_timer >= random_sound_cd:
		random_sound_timer -= random_sound_cd
		var sound_reference_data: SoundReferenceData = random_sound_pool.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound_reference_data.id, sound_reference_data.type, global_position, 0.9, 1.1, -5.0, 5.0)
