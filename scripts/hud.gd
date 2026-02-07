extends CanvasGroup

#gecici olarak money ve oil miktari 0
@export var oil_label: Label
@export var money_label: Label

func update_oil(amount):
	oil_label.text = "Oil: " + str(amount)

func update_money(amount):
	oil_label.text = "Money: " + str(amount)
