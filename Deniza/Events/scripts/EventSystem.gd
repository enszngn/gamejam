extends Node

@export var events: Array[GameEvent] # Drag your .tres files here
@export var popup_scene: PackedScene # Drag EventPopup.tscn here

@onready var timer = $Timer

func _ready():
	randomize()
	start_timer()

func start_timer():
	# Pick a random time between 10 and 30 seconds
	var wait_time = randf_range(5.0, 10.0)
	timer.start(wait_time)

func _on_timer_timeout():
	if events.size() > 0:
		spawn_event()
	
	# Restart the timer for the next event
	start_timer()

func spawn_event():
	# 1. Pick a random event
	var random_event = events.pick_random()
	
	# 2. Create the popup
	var popup_instance = popup_scene.instantiate()
	add_child(popup_instance)
	
	# 3. Fill it with data
	popup_instance.set_event_data(random_event)
