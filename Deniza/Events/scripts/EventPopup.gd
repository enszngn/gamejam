extends CanvasLayer

@onready var title_label = $Window/MarginContainer/Content/TitleLabel
@onready var desc_label = $Window/MarginContainer/Content/DescLabel
@onready var close_button = $Window/MarginContainer/Content/CloseButton

func _ready():
	# Hide the popup when the game starts
	hide()

func set_event_data(data: GameEvent):
	# Your code here is perfectly fine!
	title_label.text = data.title
	desc_label.text = data.description
	self.show()
	print("Popup açıldı! Olay: " + data.title)
func _on_close_button_pressed():
	# self.hide() <-- You don't need this if you destroy it
	
	# This is the important part:
	queue_free()
