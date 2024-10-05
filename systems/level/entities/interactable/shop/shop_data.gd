class_name ShopData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var items_for_sale: Array[BlockData]
## How much I pay YOU for YOUR goods
@export var sell_rate: float = 0.7
## How much YOU pay ME for MY goods
@export var buy_rate: float = 1.3

@export var dialogue_speaker_data: DialogueSpeakerData

@export var table_top_offset: Vector3
@export var table_offset: Vector3
@export var table_model: PackedScene
