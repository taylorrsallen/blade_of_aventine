class_name BallisticProjectile extends ProjectileBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const HITS_METAL: SoundPoolData = preload("res://resources/sounds/hits/hits_metal.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$DamagingArea3D.dealt_damage.connect(_on_damage_dealt)
	start_position = global_position
	_do_the_thing()

func _physics_process(delta: float) -> void:
	velocity = global_position - previous_position
	previous_position = global_position
	
	match data.trajectory:
		ProjectileData.Trajectory.ARC_ROLLING:
			distance += data.speed * delta
			var distance_from_start: float = start_distance - distance
			var distance_percent: float = 1.0 - (distance_from_start / start_distance)
			global_position = start_position + flat_direction * distance
			global_position.y = data.curve.sample(distance_percent) * 3.0
			global_position.y += lerpf(start_position.y, 0.0, distance_percent)
			
			rotate_x(data.speed * delta)
			
			#var temp: Vector3 = Vector3(start_position.x, 0.0, start_position.z)
			#DebugDraw3D.draw_line(temp + flat_direction * start_distance, temp + flat_direction * start_distance + Vector3.UP * 5.0, Color.RED, delta)
			
			if distance >= start_distance && $DamagingArea3D.active: _on_damage_dealt(null)
		ProjectileData.Trajectory.ARC_LEADING:
			distance += data.speed * delta
			var distance_from_start: float = start_distance - distance
			var distance_percent: float = 1.0 - (distance_from_start / start_distance)
			global_position = start_position + flat_direction * distance
			global_position.y = data.curve.sample(distance_percent) * 3.0
			global_position.y += lerpf(start_position.y, 0.0, distance_percent)
			
			var look_transform: Transform3D = Transform3D()
			look_transform.origin = global_position
			#DebugDraw3D.draw_sphere(global_position, 0.1, Color.RED)
			#DebugDraw3D.draw_sphere(previous_position, 0.1, Color.BLUE)
			#DebugDraw3D.draw_sphere(global_position + global_position - previous_position, 0.1, Color.ORANGE)
			look_transform = look_transform.looking_at((global_position + global_position - previous_position))
			global_basis = look_transform.basis
			
			#var temp: Vector3 = Vector3(start_position.x, 0.0, start_position.z)
			#DebugDraw3D.draw_line(temp + flat_direction * start_distance, temp + flat_direction * start_distance + Vector3.UP * 5.0, Color.RED, delta)
			
			if distance >= start_distance && $DamagingArea3D.active: _on_damage_dealt(null)
		_:
			global_position += direction * data.speed * delta
			if global_position.y <= 0.0 && $DamagingArea3D.active: _on_damage_dealt(null)
	
	lifetime_timer += delta
	if lifetime_timer >= data.lifetime: queue_free()
	
	pierce_delay_timer += delta
	if pierce_delay_timer >= data.pierce_delay:
		pierce_delay_timer -= data.pierce_delay
		$DamagingArea3D.active = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damage_dealt(body: PhysicsBody3D) -> void:
	var deflection: bool
	
	if is_instance_valid(body) && body is DamageableArea3D && body.get_parent() is Character:
		deflection = data.damage_data.damage_type == DamageData.DamageType.SHARP && body.get_parent().body_data.flat_armor > 0.0
	
	if is_instance_valid(body) && data.stick_in_target && !deflection:
		var projectile_model: Node3D = data.model_scene.instantiate()
		projectile_model.position = global_position - global_basis.z * 0.5
		projectile_model.rotation = rotation
		if body is Character:
			body.body_container.add_child(projectile_model)
		elif body is DamageableArea3D:
			if body.get_parent() is Character:
				Util.main.add_child(projectile_model)
				projectile_model.reparent(body.get_parent().body_container)
			else:
				body.add_child(projectile_model)
		else:
			body.add_child(projectile_model)
	
	var hit_sound: SoundReferenceData
	if deflection:
		hit_sound = HITS_METAL.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(hit_sound.id, hit_sound.type, global_position, 0.9, 1.1, hit_sound.volume_db, 5.0)
	elif data.hit_sounds:
		hit_sound = data.hit_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(hit_sound.id, hit_sound.type, global_position, 0.9, 1.1, hit_sound.volume_db, 5.0)
	
	if data.hit_effect:
		var effect: Node3D = data.hit_effect.instantiate()
		effect.position = global_position
		Util.main.add_child(effect)
	
	if data.aoe_radius > 0.0: _deal_aoe()
	
	if data.die_on_contact:
		_destroy()
	elif data.piercing_hits > 0:
		if pierce_count == data.piercing_hits:
			_destroy()
		else:
			$DamagingArea3D.active = false
			pierce_delay_timer = 0.0
			pierce_count += 1
