extends CombatUnit
class_name MeleeUnit

@onready var weapon: Sprite2D = $Pivot/Weapon

func die():
	weapon.hide()
	super()
	
func stop():
	super()


