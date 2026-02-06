extends Node2D

@export var speed = 300.0

func _physics_process(delta):
	# Ok tuşları veya WASD ile yönü al (Vector2 döndürür: -1, 0, 1)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		# Yön varsa hızı o yöne uygula
		velocity = direction * speed
	else:
		# Tuşa basılmıyorsa hemen dur (Kayma efekti istersen burası değişir)
		velocity = Vector2.ZERO

	# Godot 4'ün yerleşik hareket fonksiyonu
	move_and_slide()
