extends CanvasLayer

@onready var oil_label = $Control/HBoxContainer/oilLabel
@onready var money_label = $Control/HBoxContainer/moneyLabel

func _ready():
	# A. Set the text immediately when the game starts (so it doesn't say "Label")
	update_oil_text(GameManager.oil)
	update_money_text(GameManager.money)
	
	# B. CONNECT TO SIGNALS (The most important part)
	# Syntax: Who.SignalName.connect(FunctionToRun)
	GameManager.oil_changed.connect(update_oil_text)
	GameManager.money_changed.connect(update_money_text)

func update_oil_text(new_amount):
	oil_label.text = "Oil: " + str(new_amount)

func update_money_text(new_amount):
	money_label.text = "Money: " + str(new_amount)
