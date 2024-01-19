extends Marker2D

var unit_scenes : Array = [preload("res://scenes/knight.tscn"),
					preload("res://scenes/elf.tscn"),
					preload("res://scenes/heavy.tscn"),
					preload("res://scenes/supporter.tscn"),
					preload("res://scenes/lumberjack.tscn")
					]

@onready var combat_unit_spawn_point: Marker2D = $CombatUnitSpawnPoint
@onready var gatherer_unit_spawn_point: Marker2D = $GathererUnitSpawnPoint


@export var team : Globals.Teams

@export var spawn_interval : float

var elapsed_time : float
var world : Node2D

signal unit_spawned(unit : Unit)

func _ready() -> void:
	world = get_parent()
	unit_spawned.connect(world._on_unit_spawned)
	if team == Globals.Teams.AI:
		AIControler.unit_purchased.connect(_on_ai_unit_buy)

func spawn_unit(unit_type : Globals.Units):
	var unit : Unit = unit_scenes[unit_type].instantiate()
	unit.team = team
	unit.unit_type = unit_type
	if unit is Gatherer:
		unit.global_position = gatherer_unit_spawn_point.global_position
		if unit.team == Globals.Teams.PLAYER:
			unit.base = %BlueVault
		else:
			unit.base = %RedVault
	else:
		unit.global_position = combat_unit_spawn_point.global_position
		
	unit_spawned.emit(unit)

func _on_ai_unit_buy(unit_type : Globals.Units):
	spawn_unit(unit_type)
