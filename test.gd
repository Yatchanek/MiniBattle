extends Node2D

@onready var polygon_2d: Polygon2D = $Triangle/Polygon2D
@onready var polygon_2d_2: Polygon2D = $Triangle/Polygon2D2
@onready var polygon_2d_3: Polygon2D = $Triangle/Polygon2D3
@onready var sprite: Sprite2D = $Triangle/Sprite2D
@onready var a: Line2D = $Triangle/A
@onready var b: Line2D = $Triangle/B
@onready var c: Line2D = $Triangle/C
@onready var d: Line2D = $Triangle/D
@onready var collision_shape_2d: CollisionShape2D = $Triangle/Area2D/CollisionShape2D
@onready var triangle: Node2D = $Triangle

const SIDE_LENGTH : int = 200
var reference_points : PackedVector2Array
var transformed_points : PackedVector2Array
var transformed_middle : Vector2
var height : float
var middle : Vector2
var dir_a : Vector2
var dir_b : Vector2
var dir_c : Vector2

var area : float

func _ready() -> void:
	height = sqrt(3) * SIDE_LENGTH * 0.5
	var points : PackedVector2Array = []
	reference_points.append(Vector2(0, 0))
	reference_points.append(Vector2(0 + SIDE_LENGTH * 0.5, height))
	reference_points.append(Vector2(0 - SIDE_LENGTH* 0.5, height))
	middle = reference_points[0] + Vector2(0, height * 2/3)
	transformed_points = triangle.global_transform * reference_points
	transformed_middle = triangle.global_transform * middle
	var points_1 : PackedVector2Array
	var points_2 : PackedVector2Array
	var points_3 : PackedVector2Array
	points_1.append(reference_points[0])
	points_1.append(reference_points[1])
	points_1.append(middle)
	points_2.append(reference_points[1])
	points_2.append(reference_points[2])
	points_2.append(middle)
	points_3.append(reference_points[2])
	points_3.append(reference_points[0])
	points_3.append(middle)
	sprite.position = middle
	polygon_2d.polygon = points_1
	polygon_2d_2.polygon = points_2
	polygon_2d_3.polygon = points_3
	collision_shape_2d.shape.points = reference_points
	a.add_point(reference_points[0])
	b.add_point(reference_points[1])
	c.add_point(reference_points[2])
	d.add_point(middle)
	a.add_point(middle)
	b.add_point(middle)
	c.add_point(middle)
	d.add_point(middle)
	dir_a = reference_points[0].direction_to(reference_points[1])
	dir_b = reference_points[1].direction_to(reference_points[2])
	dir_c = reference_points[2].direction_to(reference_points[0])
	
	area = snappedf(0.5 * SIDE_LENGTH * height, 0.0001)
	$VBoxContainer/Area.text = str(area)
	
func _process(delta: float) -> void:
	var pos = get_global_mouse_position()
	if Geometry2D.point_is_inside_triangle(pos, transformed_points[0], transformed_points[1], transformed_points[2]):
		sprite.position = triangle.to_local(pos) 
	else:
		var state = get_world_2d().direct_space_state
		var query : PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
		query.collide_with_areas = true
		query.from = pos
		query.to = transformed_middle
		var collision = state.intersect_ray(query)
		if collision:
			sprite.position = triangle.to_local(collision.position)
			
	a.points[1] = sprite.position
	b.points[1] = sprite.position
	c.points[1] = sprite.position	
	d.points[1] = pos
	polygon_2d.polygon[2] = sprite.position
	polygon_2d_2.polygon[2] = sprite.position
	polygon_2d_3.polygon[2] = sprite.position
	
	var dir_a_pos = reference_points[0].direction_to(sprite.position)
	var angle_a = abs(dir_a.angle_to(dir_a_pos))
	var length = reference_points[0].distance_to(sprite.position)
	var area_a = 0.5 * SIDE_LENGTH * length * sin(angle_a)
	
	var dir_b_pos = reference_points[1].direction_to(sprite.position)
	var angle_b = abs(dir_b.angle_to(dir_b_pos))
	length = reference_points[1].distance_to(sprite.position)
	var area_b = 0.5 * SIDE_LENGTH * length * sin(angle_b)

	var dir_c_pos = reference_points[2].direction_to(sprite.position)
	var angle_c = abs(dir_c.angle_to(dir_c_pos))
	length = reference_points[2].distance_to(sprite.position)
	
	var area_c = 0.5 * SIDE_LENGTH * length * sin(angle_c)
	
	$VBoxContainer/A.text = str(snappedf(area_b / area, 0.0001))
	$VBoxContainer/B.text = str(snappedf(area_c / area, 0.0001))
	$VBoxContainer/C.text = str(snappedf(area_a / area, 0.0001))
