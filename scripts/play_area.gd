extends Node2D

@onready var blue_spawner: Marker2D = $BlueSpawner

@onready var nav_polygon : NavigationPolygon = $NavigationRegion2D.navigation_polygon
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D

@export var resource_grid_start_left : Vector2i
@export var grid_size : int

var resource_grid_start_right : Vector2i

@export var max_grid_depth_horizontal : int = 3
@export var max_grid_depth_vertical : int = 3
@export var max_trees : int = 10
@export var max_mines : int = 4

var taken_positions : Array = []

var hit_label_scene = preload("res://scenes/hit_label.tscn")
var tree_scene = preload("res://scenes/tree.tscn")
var stone_scene = preload("res://scenes/stone.tscn")

var drag_started : bool = false
var obstacle_data : NavigationMeshSourceGeometryData2D

var player_resources : Dictionary = {
	Globals.Resources.WOOD: 200,
	Globals.Resources.STONE: 0
}

signal unit_purchased

func _ready() -> void:
	for button : TextureButton in get_tree().get_nodes_in_group("BuyUnitButtons"):
		button.pressed.connect(_on_buy_button_pressed.bind(button))
	obstacle_data = NavigationMeshSourceGeometryData2D.new()
	unit_purchased.connect(Globals._on_unit_purchased)

	var resource_area_width = 1280 - 192 - 2 * %BlueBase.width
	var points : PackedVector2Array = generate_poisson_points(80.0, Vector2(resource_area_width, 250))
	var play_area_transform = Transform2D(0, Vector2(192 + %BlueBase.width, 425))
	points = play_area_transform * points
	create_resources(points)
	await get_tree().process_frame
	update_obstacles()
	
func create_resources(candidate_points):
	for i in range(min(max_trees, candidate_points.size())):
		var idx = randi() % candidate_points.size()
		var pos = candidate_points[idx]
		candidate_points.remove_at(idx)
		
		var tree = tree_scene.instantiate()
		tree.global_position = pos
		call_deferred("add_child", tree)

	for i in range(min(max_mines, candidate_points.size())):
		var idx = randi() % candidate_points.size()
		var pos = candidate_points[idx]
		candidate_points.remove_at(idx)
		
		var stone = stone_scene.instantiate()
		stone.global_position = pos
		call_deferred("add_child", stone)

func update_obstacles():
	obstacle_data.clear()
	for obstacle : ResourceArea in get_tree().get_nodes_in_group("Obstacles"):
		var new_polygon = obstacle.col_shape.global_transform * obstacle.col_shape.polygon
		obstacle_data.add_obstruction_outline(new_polygon)
	NavigationServer2D.bake_from_source_geometry_data(nav_polygon, obstacle_data)

	navigation_region_2d.navigation_polygon = nav_polygon



func generate_poisson_points(radius : float, _region_size : Vector2i):
	var cell_size : float = radius / sqrt(2.0)
	var region_size : Vector2 = _region_size

	var grid = []
	grid.resize(ceil(region_size.x / cell_size))
	for i in grid.size():
		grid[i] = []
		grid[i].resize(ceil(region_size.y / cell_size))
		for j in grid[i].size():
			grid[i][j] = 0
	
	var points : PackedVector2Array = []
	var spawn_points : PackedVector2Array = []
	spawn_points.append(region_size * 0.5)

	while spawn_points.size() > 0:
		var index : int = randi() % spawn_points.size()
		var spawn_center : Vector2 = spawn_points[index]
		var accepted : bool = false

		for _i in range(20):
			var angle : float = randf_range(0, TAU)
			var dir : Vector2 = Vector2.RIGHT.rotated(angle)
			var candidate : Vector2 = spawn_center + dir * randf_range(radius, radius * 2)
			
			if is_valid(candidate, region_size, cell_size, radius, points, grid):
				points.append(candidate)
				spawn_points.append(candidate)
				grid[int(candidate.x / cell_size)][int(candidate.y / cell_size)] = points.size()
				accepted = true
				break
		if !accepted:
			spawn_points.remove_at(index)
	
	return points

func is_valid(candidate : Vector2, region_size : Vector2, cell_size : float, radius : float, points : PackedVector2Array, grid : Array):
	if candidate.x >= 0 and candidate.x < region_size.x and candidate.y >=0 and candidate.y < region_size.y:
		var cell_x : int = candidate.x / cell_size
		var cell_y : int = candidate.y / cell_size
		
		var search_start_x = max(0, cell_x - 2)
		var search_start_y = max(0, cell_y - 2)
		var search_end_x = min(cell_x + 2, grid.size() - 1)
		var search_end_y = min(cell_y + 2, grid[0].size() - 1)
		
		for x in range(search_start_x, search_end_x + 1):
			for y in range(search_start_y, search_end_y + 1):
				var point_index = grid[x][y] - 1
				if point_index != -1:
					var distance : float = candidate.distance_squared_to(points[point_index])
					if distance < radius * radius:
						return false
		return true
	return false


func _on_buy_button_pressed(button : TextureButton):
	var unit_type : Globals.Units = button.get_index() as Globals.Units
	if Globals.check_availability(unit_type):
		button.start_cooldown()
		blue_spawner.spawn_unit(unit_type)
		unit_purchased.emit(unit_type)

func _on_unit_hit(damage: int, pos : Vector2, crit : bool = false, text : String = ""):
	var label = hit_label_scene.instantiate()
	if text:
		label.text = text
	elif damage >= 0:
		label.text = str(damage)
	else:
		label.text = "Miss!"
	label.crit = crit
	label.global_position = pos - Vector2(label.size.x * 0.5, 0)
	call_deferred("add_child", label)

func _on_unit_spawned(unit : Node2D):
	call_deferred("add_child", unit)

func _on_projectile_fired(projectile : Projectile):
	call_deferred("add_child", projectile)

func _on_resource_removed():
	await get_tree().process_frame
	update_obstacles()
	get_tree().call_group("Gatherers", "recheck")
