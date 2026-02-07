extends Area2D

@export var player_destination: Marker2D
@export var camera_destination: Marker2D

# 3. We need to find the Main Camera automatically
@onready var main_camera = get_viewport().get_camera_2d()

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if it is the player
	if body.name == "player":
		print("Are you entering")
		if player_destination and camera_destination:
			switch_room(body)
		else:
			print("ERROR: Teleporter missing destinations!")

func switch_room(player):
	# A. Move the Player
	player.global_position = player_destination.global_position
	
	# Stop the player's movement so they don't walk back
	player.target_position = player_destination.global_position
	player.velocity = Vector2.ZERO
	
	# B. Move the Camera
	if main_camera:
		main_camera.global_position = camera_destination.global_position
	else:
		print("ERROR: No Camera2D found in the scene!")
