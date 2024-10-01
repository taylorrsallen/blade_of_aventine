extends Area3D
class_name DamageableArea3D

signal damaged(damage_data: DamageData, area_id: int)

@export var id: int

func damage(damage_data: DamageData) -> void:
	damaged.emit(damage_data, id)
