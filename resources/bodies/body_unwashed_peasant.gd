class_name BodyUnwashedPeasant extends CharacterBody

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
#func advance_movement_step(delta: float, animation_steps: int) -> void:
	#if walking_target < 0.05: return
	#Animation 2
	#var ground_speed_value: float = 1.0 #animation_tree["parameters/base_movement/blend_amount"]
	#
	#var step_time: float = jog_step_time
	#if ground_speed_value <= 0.0:
		#step_time = lerpf(step_time, walk_step_time, -ground_speed_value)
	#else:
		#step_time = lerpf(step_time, sprint_step_time, ground_speed_value)
	#
	#current_movement_step_time += delta
	#if current_movement_step_time >= step_time:
		#current_movement_step_time -= step_time
		#current_movement_step = (current_movement_step + 1) % animation_steps
		#
		#if current_movement_step == 0 || current_movement_step == animation_steps * 0.5: try_emit_footstep()
	#
	#const step_factor: float = 1.625 / ANIMATION_FRAMES
	#animation_tree["parameters/movement_step/seek_request"] = current_movement_step * step_factor

#func try_emit_footstep() -> void:
	#var noise: float = (animation_tree["parameters/base_movement_blend/blend_position"] + 1.0) * 0.5
	#print(noise)
	#SoundManager.play_pitched_3d_sfx(0, SoundDatabase.SoundType.SFX_FOOTSTEP, global_position, 0.9, 1.1, -20.0 + 5.0 * noise, 10.0 + 5.0 * noise)
	#if ray.is_colliding():
		#var collider = ray.get_collider()
		#if collider is Terrain3D:
			#var matter_id: int = collider.storage.get_texture_id(ray.get_collision_point()).x
			#if ray.get_collision_normal().dot(Vector3.UP) <= 0.90: matter_id = 1
			#var noise: float = (animation_tree["parameters/ground_speed/blend_amount"] + 1.0) * 0.5
			#Game.spawn_footstep(matter_id, noise, ray.get_collision_point())
		#else: if collider is MatterBody:
			#var noise: float = (animation_tree["parameters/ground_speed/blend_amount"] + 1.0) * 0.5
			#Game.spawn_footstep(collider.matter_id, noise, ray.get_collision_point())
