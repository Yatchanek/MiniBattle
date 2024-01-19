extends Node2D
class_name Unit

@export var unit_name : String
@export var unit_data : UnitData

@export var team : Globals.Teams

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Pivot/Sprite2D

enum States {
	MOVE,
	FIGHT,
	CAST,
	FORAGE,
	UNLOAD,
	WAIT,
	IDLE
}

var current_state : States
var previous_state : States

var velocity : Vector2
var unit_type : Globals.Units

signal died(_unit_type : Globals.Units)
signal spawn_label(damage : int, pos : Vector2, crit : bool)

func _ready() -> void:
	if team == Globals.Teams.AI:
		sprite_2d.texture = load("res://graphics/enemy_units_rev.png")
		ready.connect(AIControler._on_unit_spawned.bind(unit_type))
		died.connect(AIControler._on_unit_died.bind(unit_type))
	else:
		ready.connect(Globals._on_unit_spawned.bind(unit_type))
		died.connect(Globals._on_unit_died.bind(unit_type))

func attack_target():
	pass
	
func prepare_to_attack():
	pass

func switch_state(new_state : States):
	match new_state:
		States.MOVE:
			animation_player.play("Walk")
		States.IDLE:
			animation_player.play("Idle")
		States.WAIT:
			animation_player.play("Idle")
		States.FIGHT:
			prepare_to_attack()
		States.CAST:
			attack_target()
		States.FORAGE:
			animation_player.play("Work")	
		States.UNLOAD:
			animation_player.play("Idle")
	previous_state = current_state
	current_state = new_state


	
