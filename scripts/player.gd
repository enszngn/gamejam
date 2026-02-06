extends CharacterBody2D

# Karakterin hızı
var speed = 400.0

# Gideceğimiz hedef nokta (Başlangıçta kendi yeri)
var target_position = Vector2.ZERO

# TileMapLayer'a erişmemiz lazım. 
@onready var tile_map_layer = $"../../room1/TileMapLayer"

#clickmarker'a erismek icin
@onready var click_marker = $"../../clickmarker"
var marker_tween: Tween

func _ready():
	# Oyun başlar başlamaz (0,0)'a koşmasın diye hedefi olduğu yer yapıyoruz
	target_position = global_position

func _input(event):
	# Sol tık algılama
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 1. Mouse nerede? (Global Dünya Koordinatı)
		var mouse_global = get_global_mouse_position()
		show_marker_anim(mouse_global)
		
		# 2. Bu mouse pozisyonu TileMap'in içinde hangi yerel koordinata denk geliyor?
		var mouse_local = tile_map_layer.to_local(mouse_global)
		
		# 3. Bu yerel koordinat hangi KAREYE (Grid ID: 2,5 gibi) denk geliyor?
		var map_coord = tile_map_layer.local_to_map(mouse_local)
		
		# 4. O karenin MERKEZİ neresi? (Godot 4 map_to_local ile direkt merkezi verir!)
		var tile_center_local = tile_map_layer.map_to_local(map_coord)
		
		# 5. O merkezi tekrar Global Dünya Koordinatına çevir ki karakter oraya gidebilsin
		target_position = tile_map_layer.to_global(tile_center_local)
		
		# Konsola nereye gideceğini yazdıralım (Test için)
		print("Gidilen Kare: ", map_coord)

func _physics_process(_delta):
	# Hedefe olan X ve Y farklarını ayrı ayrı hesapla
	var x_diff = target_position.x - global_position.x
	var y_diff = target_position.y - global_position.y
	
	# Hata payı (titremeyi önlemek için 4 piksel tolerans)
	var threshold = 4.0
	
	# Önce X ekseninde (Yatay) hizalanmaya çalış
	if abs(x_diff) > threshold:
		velocity.x = sign(x_diff) * speed # Yönü bul (-1 veya 1) ve hızla çarp
		velocity.y = 0                     # Y hareketini iptal et (Çapraz gidemesin)
		
	# Eğer X ekseninde hedefi tutturduysak, Y eksenine (Dikey) bak
	elif abs(y_diff) > threshold:
		velocity.x = 0                     # X hareketini iptal et
		velocity.y = sign(y_diff) * speed  # Yönü bul ve hızla çarp
		
	else:
		# Hedefe vardık, tam merkeze otur ve dur
		velocity = Vector2.ZERO
		global_position = target_position
	
	# Hareketi uygula
	move_and_slide()

func show_marker_anim(pos):
	# 1. Güvenlik önlemi: Marker bağlı değilse oyunu çökertme, dur.
	if not click_marker:
		return

	# 2. Eğer eski bir animasyon hala oynuyorsa onu iptal et.
	if marker_tween:
		marker_tween.kill()

	# 3. Marker'ı ışınla ve ayarlarını sıfırla
	click_marker.global_position = pos
	click_marker.visible = true
	click_marker.modulate.a = 1.0

	# 4. Yeni animasyon başlat
	marker_tween = get_tree().create_tween()

	# 0.5 saniyede şeffaflığı (alpha) 0'a indir
	marker_tween.tween_property(click_marker, "modulate:a", 0.0, 0.5)

	# Animasyon bitince "hide" fonksiyonunu çağırıp tamamen gizle
	marker_tween.tween_callback(click_marker.hide)
