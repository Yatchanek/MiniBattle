extends Node2D
class_name Vault

@export var team : Globals.Teams
@onready var detector: Area2D = $Detector

func _ready() -> void:
	if team == Globals.Teams.PLAYER:
		detector.collision_layer = 64
	else:
		detector.collision_layer = 128
