class_name ShopItemDisplay extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal interacted(item_display: ShopItemDisplay, source: Character, controller: PlayerController)
signal buy_block_from_character(block_data: BlockData, character: Character)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var block_data: BlockData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func interact(source: Character, controller: PlayerController) -> void:
	interacted.emit(self, source, controller)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func give_coins_for_block(_block_data: BlockData, character: Character) -> void:
	buy_block_from_character.emit(_block_data, character)

func will_buy(block_pile: BlockPile) -> bool:
	for item in get_parent().get_parent().data.items_that_shop_will_buy:
		if item == block_pile.blocks[0]: return true
	return false
