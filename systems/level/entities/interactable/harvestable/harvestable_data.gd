class_name HarvestableData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_category("Core")
@export var name: String
@export var model_scene: PackedScene
@export var height: float
@export var radius: float
@export var random_rotation: bool

@export_category("Drops")
@export var block_drops: Array[BlockData] = []
@export var pickup_drops: DropsData

@export_category("Break")
@export var scepter_hits_to_break: int = -10

@export_category("Interactable")
@export var interactable_data: InteractableData
