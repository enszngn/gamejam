extends Node

#as a good practice, variables about money and oil should be here, disconnected from everything else
var oil: int = 0
var money: int = 0
var oil_storage: int = 1000

#i've also learned that rather than updating the amount of oil and money every frame,
#making our other scripts scream OIL_CHANGED everytime oil changes is a better way to do it.
signal oil_changed(new_amount)
signal money_changed(new_amount)
signal storage_changed(new_amount)

#these are for the teleportation
var next_spawn_pos: Vector2 = Vector2.ZERO

func add_oil(amount: int):
	oil += amount
	oil_changed.emit(oil)
	
func add_money(amount: int):
	money += amount
	money_changed.emit(money)

func add_storage(amount: int):
	oil_storage += amount
	storage_changed.emit(oil_storage)
