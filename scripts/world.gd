extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var blue_spawner: Marker2D = $PlayArea/BlueSpawner

@onready var nav_polygon : NavigationPolygon = $PlayArea/NavigationRegion2D.navigation_polygon
@onready var navigation_region_2d: NavigationRegion2D = $PlayArea/NavigationRegion2D
@onready var play_area: Node2D = $PlayArea

var obstacle_data : NavigationMeshSourceGeometryData2D

var drag_started : bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()

	elif event is InputEventMouseButton:
		if event.pressed and event.position.x > 192 and event.button_index == MOUSE_BUTTON_LEFT:
			drag_started = true
		elif not event.pressed:
			drag_started = false
			
	elif event is InputEventMouseMotion:
		if drag_started:
			play_area.position.x = clamp(play_area.position.x + event.relative.x * 0.75, -(%RedBase.position.x - 1088), 192)
