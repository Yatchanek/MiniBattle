extends Area2D

@export var attacker : Unit

var attack_power : int

func _ready() -> void:
	if attacker.team == Globals.Teams.PLAYER:
		collision_layer = 4
	else:
		collision_layer = 8
