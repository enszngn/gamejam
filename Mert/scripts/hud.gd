extends Control

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var oil_label: Label = $TopBar/OilLabel
@onready var pressure_bar: TextureProgressBar = $TopBar/PressureBar
@onready var pressure_label: Label = $TopBar/PressureLabel

func _ready() -> void:
	GameState.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	money_label.text = "Money: $" + str(GameState.money)
	oil_label.text = "Oil: " + str(GameState.oil)

	pressure_bar.max_value = GameState.pressure_max
	pressure_bar.value = GameState.pressure

	var pct: int = int(round((GameState.pressure / GameState.pressure_max) * 100.0)) if GameState.pressure_max > 0.0 else 0
	pressure_label.text = "Pressure: " + str(pct) + "%"
