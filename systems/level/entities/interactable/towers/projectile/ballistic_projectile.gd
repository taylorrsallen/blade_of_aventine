class_name BallisticProjectile extends ProjectileBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$DamagingArea3D.dealt_damage.connect(_on_damage_dealt)
	start_position = global_position

func _physics_process(delta: float) -> void:
	if data.trajectory == data.Trajectory.LINEAR:
		global_position += direction * data.speed * delta
		if global_position.y <= 0.0 && $DamagingArea3D.active: _on_damage_dealt()
	else:
		distance += data.speed * delta
		var distance_from_start: float = start_distance - distance
		var distance_percent: float = 1.0 - (distance_from_start / start_distance)
		global_position = start_position + flat_direction * distance
		global_position.y = data.curve.sample(distance_percent) * 3.0
		global_position.y += lerpf(start_position.y, 0.0, distance_percent)
		
		rotate_z(data.speed * delta)
		
		#var temp: Vector3 = Vector3(start_position.x, 0.0, start_position.z)
		#DebugDraw3D.draw_line(temp + flat_direction * start_distance, temp + flat_direction * start_distance + Vector3.UP * 5.0, Color.RED, delta)
		
		if distance >= start_distance && $DamagingArea3D.active: _on_damage_dealt()
	
	lifetime_timer += delta
	if lifetime_timer >= data.lifetime: queue_free()
	
	pierce_delay_timer += delta
	if pierce_delay_timer >= data.pierce_delay:
		pierce_delay_timer -= data.pierce_delay
		$DamagingArea3D.active = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damage_dealt() -> void:
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
