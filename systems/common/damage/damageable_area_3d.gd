class_name DamageableArea3D extends StaticBody3D

signal damaged(damage_data: DamageData, area_id: int, source: Node)

@export var id: int

func damage(damage_data: DamageData, source: Node) -> void:
	damaged.emit(damage_data, id, source)

func damage_sourceless(damage_data: DamageData) -> void:
	damaged.emit(damage_data, id, null)
