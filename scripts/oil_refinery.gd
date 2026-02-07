extends Node2D
var amount = 100

func _on_production_timer_timeout() -> void:
	GameManager.add_oil(amount)
