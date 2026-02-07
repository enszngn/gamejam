extends Panel

signal building_selected(building_type: int)

# BuildSystem ile aynı enum sırası: 0 NORMAL, 1 EXTRACTOR (birazdan uyumlu yapacağız)
const NORMAL := 0
const EXTRACTOR := 1

@onready var extractor_btn: Button = $VBoxContainer/ExtractorButton
@onready var normal_btn: Button = $VBoxContainer/NormalButton
@onready var build_menu: Panel = $"../UI/BuildMenu"


func _ready() -> void:
	extractor_btn.pressed.connect(func(): building_selected.emit(EXTRACTOR))
	normal_btn.pressed.connect(func(): building_selected.emit(NORMAL))
