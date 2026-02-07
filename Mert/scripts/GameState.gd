extends Node

signal changed

var money: int = 0
var oil: int = 0

var pressure: float = 0.0
var pressure_max: float = 100.0

func add_money(amount: int) -> void:
	money += amount
	changed.emit()

func add_oil(amount: int) -> void:
	oil += amount
	changed.emit()

func add_pressure(amount: float) -> void:
	pressure = clamp(pressure + amount, 0.0, pressure_max)
	changed.emit()

func set_pressure(value: float) -> void:
	pressure = clamp(value, 0.0, pressure_max)
	changed.emit()
