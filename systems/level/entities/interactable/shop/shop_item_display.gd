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
