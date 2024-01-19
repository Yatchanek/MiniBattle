extends ResourceArea
class_name Stone

func _ready() -> void:
	resource_type = Globals.Resources.STONE
	resource_amount = randi_range(5000, 10000)
	super()
