extends Area3D
class_name DamagingArea3D

signal dealt_damage()

@export var active: bool = true
@export var damage_data: DamageData
@export var source: Node

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area3D) -> void:
	if active && area is DamageableArea3D:
		if is_instance_valid(source):
			area.damage(damage_data, source)
		else:
			area.damage_sourceless(damage_data)
		dealt_damage.emit()

func _on_body_entered(body: Area3D) -> void:
	if active && body.has_method("damage"):
		if is_instance_valid(source):
			body.damage(damage_data, source)
		else:
			body.damage_sourceless(damage_data)
		dealt_damage.emit()
