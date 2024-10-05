class_name BallisticProjectile extends ProjectileBase

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$DamagingArea3D.dealt_damage.connect(_on_damage_dealt)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime_timer += delta
	if lifetime_timer >= lifetime: queue_free()
	
	pierce_delay_timer += delta
	if pierce_delay_timer >= pierce_delay:
		pierce_delay_timer -= pierce_delay
		$DamagingArea3D.active = true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_damage_dealt() -> void:
	if die_on_contact:
		_destroy()
	elif piercing_hits > 0:
		if pierce_count == piercing_hits:
			_destroy()
		else:
			$DamagingArea3D.active = false
			pierce_delay_timer = 0.0
			pierce_count += 1
