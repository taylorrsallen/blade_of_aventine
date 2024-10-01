extends Area3D
class_name DamagingArea3D

@export var active: bool
@export var damage_data: DamageData

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area3D) -> void:
	if active && area is DamageableArea3D: area.damage(damage_data)

func _on_body_entered(body: Area3D) -> void:
	if active && body.has_method("damage"): body.damage(damage_data)
