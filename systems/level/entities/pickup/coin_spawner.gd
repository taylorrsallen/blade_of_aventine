class_name CoinSpawner

# (({[%%%(({[=======================================================================================================================]}))%%%]}))

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
static func get_coins_for_amount(amount: int) -> Array[PickupData]:
	var PICKUP_DATABASE: PickupDatabase = load("res://resources/pickups/pickup_database.res")
	
	#print("Attempting to spawn %s as worth of coins..." % amount)
	
	var coins: Array[PickupData] = []
	var coin_id: int = 7
	while amount > 0:
		var coin_to_try: PickupData = PICKUP_DATABASE.database[coin_id]
		var coin_amount: int = coin_to_try.metadata["coins"]
		#print("Trying coin [%s]: %s" % [coin_id, coin_to_try.name])
		if amount >= coin_amount:
			amount -= coin_amount
			coins.append(coin_to_try)
			#print("Added %s, %s remains" % [coin_to_try.name, amount])
		else:
			#print("%s is worth too much: coin is %s, and amount is %s" % [coin_to_try.name, coin_amount, amount])
			coin_id -= 1
	
	return coins
