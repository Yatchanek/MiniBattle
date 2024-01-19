extends Resource
class_name UnitData

@export_category("Common")
@export var base_max_hp : int
@export var move_speed : int
@export var unit_type : Globals.Units

@export_category("Combat Unit")
@export var base_attack_power : int
@export var base_attack_charge_duration : float
@export var base_crit_chance : float
@export var base_defense : int
@export var base_evasion : float
@export var deviation : float
@export var attack_range : int
@export var proximity_range : int
@export var sprite_width : int

@export_category("Gatherer Unit")
@export var max_capacity : int
@export var work_speed : float
@export var forage_efficiency : int
@export var unload_efficiency : int

var mutable_properties = ["max_hp", "attack_power", "defense"]
var mutable_float_properties = ["evasion", "attack_charge_duration", "crit_chance"]

var min_max_stats : Dictionary = {}

func calculate() -> Dictionary:
	var dict : Dictionary = {}
	for property in mutable_properties:
		dict["min_" + property] = floor(get("base_" + property) * (1 - deviation)) as int
		dict["max_" + property] = ceil(get("base_" + property) * (1 + deviation)) as int
	
	for property in mutable_float_properties:
		dict["min_" + property] = get("base_" + property) * (1 - deviation) as float
		dict["max_" + property] = get("base_" + property) * (1 + deviation) as float
	min_max_stats = dict
	return dict
