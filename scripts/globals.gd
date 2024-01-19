extends Node

enum Teams {
	PLAYER,
	AI
}

enum Resources {
	WOOD,
	STONE
}

enum Units {
	MELEE,
	RANGED,
	HEAVY,
	SUPPORTER,
	GATHERER
}


var player_resources : Dictionary = {
	Resources.WOOD: 9999,
	Resources.STONE: 9999
}

var unit_names : Dictionary = {
	Units.MELEE : "Knight",
	Units.RANGED : "Elf",
	Units.HEAVY : "Giant",
	Units.GATHERER : "Gatherer",
	Units.SUPPORTER : "Sorcerer"	
}

var unit_stats : Dictionary = {
}

var unit_cost : Dictionary = {
	Units.MELEE : {
		Resources.WOOD : 200,
		Resources.STONE : 0
	},
	
	Units.RANGED : {
		Resources.WOOD : 250,
		Resources.STONE : 50
	},
	
	Units.HEAVY : {
		Resources.WOOD : 600,
		Resources.STONE : 250
	},
	
	Units.GATHERER : {
		Resources.WOOD : 100,
		Resources.STONE : 0
	},

	Units.SUPPORTER : {
		Resources.WOOD : 500,
		Resources.STONE : 200
	}
}

var purchase_cooldowns : Dictionary = {
	Units.MELEE : 1.0,
	Units.RANGED : 1.75,
	Units.HEAVY : 5.0,
	Units.GATHERER : 0.75,
	Units.SUPPORTER : 10.0
}

var player_gathering_priority : float = 0.5

var player_unit_count : Dictionary = {
	"Total" : 0,
	Units.MELEE : 0,
	Units.RANGED : 0,
	Units.HEAVY : 0,
	Units.GATHERER : 0,
	Units.SUPPORTER : 0
}

var max_units : Dictionary = {
	Units.MELEE : INF,
	Units.RANGED : INF,
	Units.HEAVY : INF,
	Units.GATHERER : 10,
	Units.SUPPORTER : 2
}

signal buy_unit(unit_type : Units)
signal resource_count_updated(team : Teams, resource_type : Resources, amount : int )

func _ready() -> void:
	unit_stats[Units.MELEE] = load("res://resources/melee_unit.tres").calculate()
	unit_stats[Units.RANGED] = load("res://resources/ranged_unit.tres").calculate()
	unit_stats[Units.HEAVY] = load("res://resources/heavy.tres").calculate()
	unit_stats[Units.GATHERER] = load("res://resources/gatherer.tres").calculate()
	unit_stats[Units.SUPPORTER] = load("res://resources/support_unit.tres").calculate()

func check_availability(unit_type : Units):
	if player_unit_count[unit_type] >= max_units[unit_type]:
		return
	for resource_type : Resources in player_resources.keys():
			if player_resources[resource_type] < unit_cost[unit_type][resource_type]:
				return false
	return true	
	
func _on_resource_unloaded(amount : int, resource_type : Resources):
	player_resources[resource_type] += amount
	resource_count_updated.emit(Teams.PLAYER, resource_type, player_resources[resource_type])

func _on_unit_purchased(unit_type : Units):
	for resource_type in unit_cost[unit_type].keys():
		player_resources[resource_type] -= unit_cost[unit_type][resource_type]
		resource_count_updated.emit(Teams.PLAYER, resource_type, player_resources[resource_type])

func _on_unit_spawned(unit_type : Units):
	player_unit_count["Total"] += 1
	player_unit_count[unit_type] += 1

func _on_unit_died(unit_type : Units):
	player_unit_count["Total"] -= 1
	player_unit_count[unit_type] -= 1
