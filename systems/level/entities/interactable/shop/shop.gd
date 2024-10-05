class_name Shop extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var dialogue_world_reader: DialogueWorldReader = $DialogueWorldReader
@export var data: ShopData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	dialogue_world_reader.init()
	#dialogue_world_reader.reader.data.speaker = data.dialogue_speaker_data
	_refresh_display()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _refresh_display() -> void:
	for i in data.items_for_sale.size():
		var block_data: BlockData = data.items_for_sale[i]
		var display_model: Node3D = block_data.model.instantiate()
		display_model.scale = Vector3.ONE * 0.5
		display_model.position = Vector3(i - data.items_for_sale.size() * 0.5, 0.0, 0.0)
		print("What am I fucking DOING?")
		add_child(display_model)
