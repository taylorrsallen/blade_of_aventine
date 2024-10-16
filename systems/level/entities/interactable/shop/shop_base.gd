class_name ShopBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SHOP_ITEM_DISPLAY: PackedScene = preload("res://systems/level/entities/interactable/shop/shop_item_display.scn")
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
var PICKUP: PackedScene = load("res://systems/level/entities/pickup/pickup.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var dialogue_world_reader: DialogueWorldReader = $DialogueWorldReader
@onready var model: Node3D = $Model
@onready var items: Node = $Items

@export var data: ShopData: set = _set_data

var readied: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: ShopData) -> void:
	data = _data
	
	if !readied: return
	
	var dialogue_data: DialogueData = DialogueData.new()
	dialogue_data.speaker = data.dialogue_speaker_data
	dialogue_world_reader.reader.data = dialogue_data
	_refresh_display()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	readied = true
	data = data

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
	if is_instance_valid(source.grabbed_entity): return
	var cost: int = item_display.block_data.value * data.buy_rate
	if controller.game_resources.coins >= cost:
		model.talk()
		
		controller.game_resources.coins -= cost
		var block_pile: BlockPile = BLOCK_PILE.instantiate()
		Util.main.level.add_tile_entity(block_pile)
		block_pile.add_block(item_display.block_data)
		source.grab_entity(block_pile)
		
		var coins_to_get: Array[PickupData] = CoinSpawner.get_coins_for_amount(cost)
		var source_position: Vector3 = source.global_position
		for coin in coins_to_get:
			var pickup: Pickup = PICKUP.instantiate()
			pickup.position = source_position
			Util.main.level.add_pickup(pickup)
			pickup.pickup_data = coin
			pickup.take(self)
			await get_tree().create_timer(0.1).timeout

func _on_item_display_highlighted(item_display: ShopItemDisplay, source: Character, _controller: PlayerController) -> void:
	if is_instance_valid(source.grabbed_entity):
		if source.grabbed_entity is BlockPile:
			var will_buy: bool
			for item in data.items_that_shop_will_buy:
				if source.grabbed_entity.blocks[0] == item:
					will_buy = true
					break
			
			if will_buy:
				dialogue_world_reader.reader.print_string("%s as, I will pay" % [roundf(source.grabbed_entity.blocks[0].value * data.sell_rate)])
			else:
				dialogue_world_reader.reader.print_string("I don't want that!")
	else:
		dialogue_world_reader.reader.print_string("%s as, you will pay" % [roundf(item_display.block_data.value * data.buy_rate)])

func _on_item_display_unhighlighted(_item_display: ShopItemDisplay, _source: Character, _controller: PlayerController) -> void:
	dialogue_world_reader.reader.clear()

func _on_buy_block_from_character(block_data: BlockData, character: Character) -> void:
	var amount_owed: int = block_data.value * data.sell_rate
	var coins_to_give: Array[PickupData] = CoinSpawner.get_coins_for_amount(amount_owed)
	for coin in coins_to_give:
		var pickup: Pickup = PICKUP.instantiate()
		pickup.position = global_position
		Util.main.level.add_pickup(pickup)
		pickup.pickup_data = coin
		if is_instance_valid(character): pickup.take(character)
		await get_tree().create_timer(0.1).timeout
