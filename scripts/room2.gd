extends LevelManager 
# Gördüğünüz gibi Node2D yerine LevelManager yazdık.
# Artık Room1, LevelManager'ın tüm özelliklerine (ışınlanma koduna) sahip!

func _ready():
	# BURASI ÇOK KRİTİK!
	# LevelManager'daki _ready'nin çalışması için 'super()' çağırmalıyız.
	super._ready() 
	
	# Buradan aşağısı sadece Room 1'e özel kodlar
	print("Oda 2 Yüklendi! Buraya özel düşmanlar doğabilir.")
	music_cal_oda1()

func music_cal_oda1():
	# Oda 1'e özel müzik kodu vs.
	pass
