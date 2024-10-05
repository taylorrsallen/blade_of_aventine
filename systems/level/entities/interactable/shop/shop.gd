class_name Shop extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SHOP_ITEM_DISPLAY: PackedScene = preload("res://systems/level/entities/interactable/shop/shop_item_display.scn")
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const PICKUP: PackedScene = preload("res://systems/level/entities/pickup/pickup.scn")
const COIN: PickupData = preload("res://resources/pickups/coin.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var dialogue_world_reader: DialogueWorldReader = $DialogueWorldReader
@onready var model: Node3D = $Model
@onready var items: Node = $Items

@export var data: ShopData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	var dialogue_data: DialogueData = DialogueData.new()
	dialogue_data.speaker = data.dialogue_speaker_data
	dialogue_world_reader.reader.data = dialogue_data
	_refresh_display()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _refresh_display() -> void:
	for child in items.get_children(): child.queue_free()
	for child in model.get_children(): child.queue_free()
	
	for i in data.items_for_sale.size():
		var block_data: BlockData = data.items_for_sale[i]
		
		var display_model: Node3D = block_data.model.instantiate()
		display_model.scale = Vector3.ONE * 0.5
		var item_display: ShopItemDisplay = SHOP_ITEM_DISPLAY.instantiate()
		item_display.position = Vector3(i - data.items_for_sale.size() * 0.5 + 0.5, 0.0, 0.0) + data.table_offset + data.table_top_offset
		item_display.block_data = block_data
		item_display.interacted.connect(_on_item_display_interacted)
		item_display.just_highlighted.connect(_on_item_display_highlighted)
		item_display.just_unhighlighted.connect(_on_item_display_unhighlighted)
		item_display.buy_block_from_character.connect(_on_buy_block_from_character)
		
		item_display.add_child(display_model)
		items.add_child(item_display)
		
		
	
	model = data.table_model.instantiate()
	model.position = data.table_offset
	add_child(model)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_item_display_interacted(item_display: ShopItemDisplay, source: Character, controller: PlayerController) -> void:
	if !is_instance_valid(source.grabbed_entity):
		var cost: int = item_display.block_data.value * data.buy_rate
		if controller.game_resources.coins >= cost:
			controller.game_resources.coins -= cost
			var block_pile: BlockPile = BLOCK_PILE.instantiate()
			Util.main.level.add_tile_entity(block_pile)
			block_pile.add_block(item_display.block_data)
			source.grab_entity(block_pile)
			while cost > 0:
				var coin_value: int = 10
				if cost < 10: coin_value = cost
				cost -= coin_value
				var pickup: Pickup = PICKUP.instantiate()
				pickup.position = source.global_position
				Util.main.level.add_pickup(pickup)
				pickup.pickup_data = COIN.duplicate()
				pickup.take(self)
				await get_tree().create_timer(0.1).timeout

func _on_item_display_highlighted(item_display: ShopItemDisplay, source: Character, controller: PlayerController) -> void:
	if is_instance_valid(source.grabbed_entity):
		if source.grabbed_entity is BlockPile:
			dialogue_world_reader.reader.print_string("%s as, I will pay" % [source.grabbed_entity.blocks[0].value * data.sell_rate])
	else:
		dialogue_world_reader.reader.print_string("%s as, you will pay" % [item_display.block_data.value * data.buy_rate])

func _on_item_display_unhighlighted(item_display: ShopItemDisplay, source: Character, controller: PlayerController) -> void:
	dialogue_world_reader.reader.clear()

func _on_buy_block_from_character(block_data: BlockData, character: Character) -> void:
	var amount_owed: int = block_data.value * data.sell_rate
	while amount_owed > 0:
		var coin_value: int = 10
		if amount_owed < 10: coin_value = amount_owed
		amount_owed -= coin_value
		var pickup: Pickup = PICKUP.instantiate()
		pickup.position = global_position
		Util.main.level.add_pickup(pickup)
		pickup.pickup_data = COIN.duplicate()
		pickup.take(character)
		await get_tree().create_timer(0.1).timeout
