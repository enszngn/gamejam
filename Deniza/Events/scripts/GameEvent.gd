extends Resource
class_name GameEvent

@export var title: String = "Event Name"
@export_multiline var description: String = "What happened?"
@export var money_loss: int = -100
@export var event_image: Texture2D # Godot 4 uses Texture2D
