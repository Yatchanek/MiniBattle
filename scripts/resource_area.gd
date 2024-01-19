extends Node2D
class_name ResourceArea

@export var resource_type : Globals.Resources
@export_range(1000, 10000) var resource_amount : int
@export var collision_half_width : int
@export var collision_half_height : int
@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionPolygon2D = $Body/CollisionForNavigation

var width : float
var height : float

signal depleted

func _ready():
	width = sprite.texture.get_width() * sprite.scale.x * 0.45
	height = sprite.texture.get_height() * sprite.scale.y * 0.3
	add_to_group("Obstacles")
	if resource_type == Globals.Resources.WOOD:
		add_to_group("Trees")
	else:
		add_to_group("GoldMines")
	label.text = str(resource_amount)
	depleted.connect(get_parent()._on_resource_removed)

func update_value():
	label.text = str(resource_amount)


func _on_body_area_entered(area: ToolBox) -> void:
	var forager : Gatherer = area.forager as Gatherer
	var amount_to_collect : int = min(forager.unit_data.forage_efficiency, resource_amount)
	
	var amount_collected : int = forager.collect(amount_to_collect)
	
	resource_amount -= amount_collected
	update_value()
	if resource_amount <= 0:
		if resource_type == Globals.Resources.WOOD:
			remove_from_group("Trees")
		else:
			remove_from_group("GoldMines")
		depleted.emit()
		queue_free()
