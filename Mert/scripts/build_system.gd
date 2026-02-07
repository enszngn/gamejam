extends Node
@export var hover_info_path: NodePath = NodePath("../UI/HoverInfo")

@onready var hover_info: Control = get_node(hover_info_path) as Control
@onready var hover_l1: Label = hover_info.get_node("VBoxContainer/Line1") as Label
@onready var hover_l2: Label = hover_info.get_node("VBoxContainer/Line2") as Label
@onready var hover_l3: Label = hover_info.get_node("VBoxContainer/Line3") as Label

@export var hover_offset: Vector2 = Vector2(16, 16)

@export var ground_path: NodePath = NodePath("../Ground")
@export var buildings_path: NodePath = NodePath("../Buildings")
@export var player_path: NodePath = NodePath("../Player")
@export var build_menu_path: NodePath = NodePath("../UI/BuildMenu")

@onready var ground: TileMapLayer = get_node(ground_path) as TileMapLayer
@onready var buildings: Node2D = get_node(buildings_path) as Node2D
@onready var player: Node2D = get_node(player_path) as Node2D
@onready var build_menu: Control = get_node(build_menu_path) as Control

@export var source_id: int = 0
@export var GRASS_ATLAS: Vector2i = Vector2i(8, 2)
@export var OIL_ATLAS: Vector2i = Vector2i(3, 11)
@export var EXTRA_BUILDABLE_GROUND: Array[Vector2i] = []

@export var build_range_tiles: int = 5

@export var extractor_rate_per_sec: int = 5      # her extractor saniyede kaç oil
@export var auto_sell: bool = false              # true yaparsan otomatik para basar
@export var price_per_oil: int = 2               # 1 oil kaç para

var extractors: Array[Node2D] = []               # sahnedeki extractor node’ları
var prod_timer: float = 0.0


enum BuildingType { NORMAL, EXTRACTOR }
var selected_building: BuildingType = BuildingType.NORMAL

var occupied: Dictionary = {} # Vector2i -> Node2D

@export var oil_per_tile: int = 200
@export var extractor_density: int = 4

var oil_region_id_by_tile: Dictionary = {}  # Vector2i -> int
var oil_regions: Array[Dictionary] = []     # index = region_id

func _ready() -> void:
	if build_menu:
		build_menu.visible = false
		if build_menu.has_signal("building_selected"):
			build_menu.connect("building_selected", Callable(self, "_on_building_selected"))

	rebuild_oil_regions()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_menu"):
		if build_menu:
			build_menu.visible = not build_menu.visible
		return

	if build_menu and build_menu.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		var tile: Vector2i = mouse_to_tile()

		if event.is_action_pressed("build_place"):
			try_place(tile)
		elif event.is_action_pressed("build_remove"):
			try_remove(tile)

func _on_building_selected(t: int) -> void:
	selected_building = BuildingType.NORMAL if t == 0 else BuildingType.EXTRACTOR
	if build_menu:
		build_menu.visible = false

func mouse_to_tile() -> Vector2i:
	var m: Vector2 = player.get_global_mouse_position()
	return ground.local_to_map(ground.to_local(m))


func player_tile() -> Vector2i:
	return ground.local_to_map(ground.to_local(player.global_position))

func in_build_range(tile: Vector2i) -> bool:
	var p: Vector2i = player_tile()
	var dx: int = abs(tile.x - p.x)
	var dy: int = abs(tile.y - p.y)
	return dx <= build_range_tiles and dy <= build_range_tiles

func get_tile_info(tile: Vector2i) -> Dictionary:
	var sid: int = ground.get_cell_source_id(tile)
	if sid == -1:
		return {"exists": false}
	return {
		"exists": true,
		"sid": sid,
		"coords": ground.get_cell_atlas_coords(tile)
	}

func is_oil_tile(tile: Vector2i) -> bool:
	var info: Dictionary = get_tile_info(tile)
	if not bool(info.get("exists", false)):
		return false
	return int(info["sid"]) == source_id and Vector2i(info["coords"]) == OIL_ATLAS

func is_ground_buildable(tile: Vector2i) -> bool:
	var info: Dictionary = get_tile_info(tile)
	if not bool(info.get("exists", false)):
		return false
	if int(info["sid"]) != source_id:
		return false

	var c: Vector2i = Vector2i(info["coords"])
	return (c == GRASS_ATLAS) or (c == OIL_ATLAS) or (c in EXTRA_BUILDABLE_GROUND)

func can_place(tile: Vector2i, btype: BuildingType) -> bool:
	if not in_build_range(tile):
		return false

	var footprint: Array[Vector2i] = get_footprint(tile, btype)

	if any_occupied(footprint):
		return false

	if btype == BuildingType.EXTRACTOR:
		if not all_tiles_oil_same_region(footprint):
			return false

		var rid: int = get_region_id_from_tiles(footprint)
		var region: Dictionary = oil_regions[rid]
		return int(region["used_extractors"]) < int(region["max_extractors"])

	for t in footprint:
		if not is_ground_buildable(t):
			return false

	return true

func try_place(tile: Vector2i) -> void:
	if not can_place(tile, selected_building):
		return

	var footprint: Array[Vector2i] = get_footprint(tile, selected_building)

	var b: Node2D = Node2D.new()
	buildings.add_child(b)
	b.global_position = ground.to_global(ground.map_to_local(tile))

	var s: Sprite2D = Sprite2D.new()
	s.texture = placeholder_tex(selected_building)
	s.centered = true
	b.add_child(s)

	b.set_meta("btype", int(selected_building))
	b.set_meta("footprint", footprint)

	if selected_building == BuildingType.EXTRACTOR:
		GameState.add_pressure(5.0)
		var rid: int = get_region_id_from_tiles(footprint)
		oil_regions[rid]["used_extractors"] = int(oil_regions[rid]["used_extractors"]) + 1
		b.set_meta("region_id", rid)
		extractors.append(b)

	for t in footprint:
		occupied[t] = b

func try_remove(tile: Vector2i) -> void:
	if not occupied.has(tile):
		return

	var b: Node2D = occupied[tile]

	if b.has_meta("region_id"):
		var rid: int = int(b.get_meta("region_id"))
		oil_regions[rid]["used_extractors"] = max(
			0,
			int(oil_regions[rid]["used_extractors"]) - 1
		)

	if b.has_meta("footprint"):
		var fp: Array = b.get_meta("footprint")
		for v in fp:
			var t: Vector2i = v
			if occupied.has(t) and occupied[t] == b:
				occupied.erase(t)
	else:
		occupied.erase(tile)
# extractor list cleanup
	if b.has_meta("btype") and int(b.get_meta("btype")) == int(BuildingType.EXTRACTOR):
		extractors.erase(b)

	b.queue_free()

func placeholder_tex(btype: BuildingType) -> Texture2D:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if btype == BuildingType.EXTRACTOR:
		img.fill(Color(1, 1, 1, 1))
	else:
		img.fill(Color(0.7, 0.7, 0.7, 1))
	return ImageTexture.create_from_image(img)

func rebuild_oil_regions() -> void:
	oil_region_id_by_tile.clear()
	oil_regions.clear()	

	var used: Dictionary = {}
	var rid: int = 0

	var cells: Array[Vector2i] = ground.get_used_cells()
	for tile in cells:
		if used.has(tile):
			continue
		if not is_oil_tile(tile):
			continue

		var tiles: Array[Vector2i] = _flood_fill_oil(tile, used)
		var size: int = tiles.size()
		var total_oil: int = size * oil_per_tile
		var max_extractors: int = max(
			1,
			int(ceil(float(size) / float(extractor_density)))
		)

		var region: Dictionary = {
		"id": rid,
		"size": size,
		"total_oil": total_oil,
		"remaining_oil": total_oil,
		"max_extractors": max_extractors,
		"used_extractors": 0
	}

		oil_regions.append(region)

		for t in tiles:
			oil_region_id_by_tile[t] = rid

		rid += 1

func _flood_fill_oil(start: Vector2i, used: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var q: Array[Vector2i] = [start]
	used[start] = true

	while q.size() > 0:
		var cur: Vector2i = q.pop_back()
		out.append(cur)

		for nb in _neighbors4(cur):
			if used.has(nb):
				continue
			if not is_oil_tile(nb):
				continue
			used[nb] = true
			q.append(nb)

	return out

func _neighbors4(p: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(p.x + 1, p.y),
		Vector2i(p.x - 1, p.y),
		Vector2i(p.x, p.y + 1),
		Vector2i(p.x, p.y - 1)
	]

func get_footprint(anchor: Vector2i, btype: BuildingType) -> Array[Vector2i]:
	if btype == BuildingType.EXTRACTOR:
		return [
			anchor,
			Vector2i(anchor.x + 1, anchor.y),
			Vector2i(anchor.x, anchor.y + 1),
			Vector2i(anchor.x + 1, anchor.y + 1)
		]
	return [anchor]

func any_occupied(tiles: Array[Vector2i]) -> bool:
	for t in tiles:
		if occupied.has(t):
			return true
	return false

func all_tiles_oil_same_region(tiles: Array[Vector2i]) -> bool:
	if tiles.size() == 0:
		return false

	var first_rid: int = -999999
	for t in tiles:
		if not is_oil_tile(t):
			return false
		if not oil_region_id_by_tile.has(t):
			return false
		var rid: int = int(oil_region_id_by_tile[t])
		if first_rid == -999999:
			first_rid = rid
		elif rid != first_rid:
			return false
	return true

func get_region_id_from_tiles(tiles: Array[Vector2i]) -> int:
	return int(oil_region_id_by_tile[tiles[0]])
	
func _process(delta: float) -> void:
	prod_timer += float(delta)
	while prod_timer >= 1.0:
		prod_timer -= 1.0
		production_tick()
		
	update_hover_info()
		
func production_tick() -> void:
	# Extractor yoksa çık
	if extractors.size() == 0:
		return

	for ex in extractors:
		if ex == null or not is_instance_valid(ex):
			continue
		if not ex.has_meta("region_id"):
			continue

		var rid: int = int(ex.get_meta("region_id"))
		if rid < 0 or rid >= oil_regions.size():
			continue

		var region: Dictionary = oil_regions[rid]
		var remaining: int = int(region.get("remaining_oil", 0))
		if remaining <= 0:
			continue

		var produced: int = min(extractor_rate_per_sec, remaining)

		# region'dan düş
		region["remaining_oil"] = remaining - produced
		oil_regions[rid] = region

		# stok / para
		GameState.add_oil(produced)
		if auto_sell:
			GameState.add_money(produced * price_per_oil)

func update_hover_info() -> void:
	if hover_info == null:
		return
	if build_menu and build_menu.visible:
		hover_info.visible = false
		return

	# UI paneli mouse yanında gezsin (screen coords)
	var mp: Vector2 = get_viewport().get_mouse_position()
	hover_info.position = mp + hover_offset

	# Dünya/tile tespiti (kamera-safe)
	var tile: Vector2i = mouse_to_tile()

	# 1) Önce: mouse altında bina var mı?
	if occupied.has(tile):
		var b: Node2D = occupied[tile]
		if b != null and is_instance_valid(b) and b.has_meta("btype"):
			var bt: int = int(b.get_meta("btype"))
			if bt == int(BuildingType.EXTRACTOR):
				_show_extractor_info(b)
				return
			else:
				_show_normal_building_info(b)
				return

	# 2) Bina yoksa: oil tile mı?
	if is_oil_tile(tile) and oil_region_id_by_tile.has(tile):
		_show_oil_region_info(tile)
		return

	hover_info.visible = false


func _show_oil_region_info(tile: Vector2i) -> void:
	var rid: int = int(oil_region_id_by_tile[tile])
	if rid < 0 or rid >= oil_regions.size():
		hover_info.visible = false
		return

	var region: Dictionary = oil_regions[rid]
	var remaining: int = int(region.get("remaining_oil", int(region.get("total_oil", 0))))
	var max_ex: int = int(region.get("max_extractors", 0))
	var used_ex: int = int(region.get("used_extractors", 0))
	var left_ex: int = max_ex - used_ex

	hover_info.visible = true
	hover_l1.text = "Oil Region #" + str(rid)
	hover_l2.text = "Oil left: " + str(remaining)
	hover_l3.text = "Extractors left: " + str(left_ex) + " (" + str(used_ex) + "/" + str(max_ex) + ")"


func _show_extractor_info(ex: Node2D) -> void:
	var rid: int = int(ex.get_meta("region_id")) if ex.has_meta("region_id") else -1
	var remaining_txt := "N/A"
	if rid >= 0 and rid < oil_regions.size():
		var region: Dictionary = oil_regions[rid]
		var remaining: int = int(region.get("remaining_oil", int(region.get("total_oil", 0))))
		remaining_txt = str(remaining)

	hover_info.visible = true
	hover_l1.text = "Extractor"
	hover_l2.text = "Rate: " + str(extractor_rate_per_sec) + " oil/s"
	hover_l3.text = "Region oil left: " + remaining_txt


func _show_normal_building_info(_b: Node2D) -> void:
	hover_info.visible = true
	hover_l1.text = "Building"
	hover_l2.text = "Type: Normal"
	hover_l3.text = ""

	
