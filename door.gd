extends Area2D

# Bu kapının kendi kimliği (Örn: "kapi_kuzey")
@export var kapi_id: String = ""

# Gidilecek Sahne Dosyası
@export_file("*.tscn") var hedef_sahne_yolu

# Gidilecek sahnede hangi kapıda doğulacağı (Örn: "kapi_guney")
@export var hedefteki_kapi_id: String = ""

func _on_body_entered(body):
	if body.is_in_group("player"): # Oyuncunun grubunu "player" yapmayı unutmayın
		sahne_degistir()

func sahne_degistir():
	# Postacıya bilgiyi ver
	GameManager.hedef_kapi_id = hedefteki_kapi_id
	
	# Sahneyi değiştir (Godot 4)
	get_tree().change_scene_to_file(hedef_sahne_yolu)
