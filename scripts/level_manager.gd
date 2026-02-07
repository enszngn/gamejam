class_name LevelManager extends Node2D
# Yukarıdaki 'class_name', bu dosyayı Godot'a tanıtır. 
# Böylece diğer dosyalarda dosya yolu aramadan direkt ismini kullanabiliriz.

@onready var player = $Player # Sahnedeki Player düğümünü bulur

# _ready fonksiyonunu burada tanımlıyoruz
func _ready():
	# Eğer bir kapı hedefi varsa oyuncuyu ışınla
	if GameManager.hedef_kapi_id != "":
		oyuncuyu_konumlandir()

func oyuncuyu_konumlandir():
	# Sahnedeki "doors" grubundaki tüm kapıları tara
	var kapilar = get_tree().get_nodes_in_group("doors")
	
	for kapi in kapilar:
		if kapi.kapi_id == GameManager.hedef_kapi_id:
			# Oyuncuyu kapının spawn noktasına taşı
			player.global_position = kapi.get_node("SpawnPoint").global_position
			break
