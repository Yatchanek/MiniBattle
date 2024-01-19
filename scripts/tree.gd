extends ResourceArea
class_name TreeResource	

func _ready() -> void:
	resource_type = Globals.Resources.WOOD
	resource_amount = randi_range(5000, 7500)
	super()
