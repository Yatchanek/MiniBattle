extends Node


enum Err {
	OK,
	NO_WOOD = 0b01,
	NO_STONE = 0b10,
	NO_RESOURCES = 0b11,
	COOLDOWN,
	MAX_REACHED,
	UNDEFINED
}

enum Priorities {
	RESOURCES,
	MILITARY
}

var ai_resources : Dictionary = {
	Globals.Resources.WOOD : 200,
	Globals.Resources.STONE : 0
}

var resource_shortage_count : Dictionary = {
	Globals.Resources.WOOD : 0,
	Globals.Resources.STONE : 0,
}

var purchase_cooldown_timers : Dictionary = {
	Globals.Units.MELEE : 0,
	Globals.Units.RANGED : 0,
	Globals.Units.HEAVY : 0,
	Globals.Units.GATHERER : 0,
	Globals.Units.SUPPORTER : 0
}

var unit_count : Dictionary = {
	"Total" : 0,
	Globals.Units.MELEE : 0,
	Globals.Units.RANGED : 0,
	Globals.Units.HEAVY : 0,
	Globals.Units.GATHERER : 0,
	Globals.Units.SUPPORTER : 0
}

var unit_priority : Dictionary = {
	Priorities.MILITARY: {
		Globals.Units.MELEE : 0.5,
		Globals.Units.RANGED : 0.25,
		Globals.Units.HEAVY : 0.1,
		Globals.Units.GATHERER : 0.1,
		Globals.Units.SUPPORTER : 0.05		
	},
	Priorities.RESOURCES: {
		Globals.Units.MELEE : 0.2,
		Globals.Units.RANGED : 0.15,
		Globals.Units.HEAVY : 0.05,
		Globals.Units.GATHERER : 0.6,
		Globals.Units.SUPPORTER : 0.0		
	}
	
}

var gathering_priority : float = 0.5
var current_priority : Priorities = Priorities.RESOURCES

signal resource_count_updated(team : Globals.Teams, resource_type : Globals.Resources, amount : int )
signal unit_purchased(unit_type : Globals.Units)
signal update_debug

func _ready() -> void:
	GlobalTimer.timeout.connect(ai_turn)
	GlobalTimer.start()

func _process(delta: float) -> void:
	for timer : Globals.Units in purchase_cooldown_timers.keys():
		purchase_cooldown_timers[timer] = clampf(purchase_cooldown_timers[timer] - delta, 0, Globals.purchase_cooldowns[timer])

func ai_turn():
	var desired_unit : Globals.Units
	var result : Err
	if unit_count["Total"] == 0:
		purchase_unit(Globals.Units.GATHERER)
		gathering_priority = 0.25
		return
	elif randf() < 0.1: 
		return
	else:
		
		if resource_shortage_count[Globals.Resources.WOOD] > 2 \
		or resource_shortage_count[Globals.Resources.STONE] > 2:
			if unit_count[Globals.Units.GATHERER] < 5:
				desired_unit = Globals.Units.GATHERER
			else:
				desired_unit = choose_unit()
			current_priority = Priorities.RESOURCES
			resource_shortage_count[Globals.Resources.WOOD] = 0
			resource_shortage_count[Globals.Resources.STONE] = 0
		else:			
			desired_unit = choose_unit()
				
		result = purchase_unit(desired_unit)

		if result == Err.COOLDOWN:
			var available_units = get_available_units()
			desired_unit = available_units.pick_random()
			
			if desired_unit:
				result = purchase_unit(desired_unit)
		elif result == Err.NO_WOOD:
			gathering_priority = clampf(gathering_priority - 0.05, 0.1, 0.9)
			resource_shortage_count[Globals.Resources.WOOD] += 1
		elif result == Err.NO_STONE:
			gathering_priority = clampf(gathering_priority + 0.05, 0.1, 0.9)
			resource_shortage_count[Globals.Resources.STONE] += 1
		elif result == Err.NO_RESOURCES:
			resource_shortage_count[Globals.Resources.WOOD] += 1
			resource_shortage_count[Globals.Resources.STONE] += 1
			
		if unit_count[Globals.Units.GATHERER] > 3:
			current_priority = Priorities.MILITARY

func choose_unit() -> Globals.Units:
	var total_chance : float = 0
	var roll : float = randf()
	var chosen_unit : Globals.Units
	for type in unit_priority[current_priority].keys():
		total_chance += unit_priority[current_priority][type]
		if roll <= total_chance:
			chosen_unit = type
			break
	return chosen_unit

func choose_spare_unit(available_units : Array):
	return available_units.pick_random()

func purchase_unit(unit_type : Globals.Units) -> Err:
	var result : Err = check_availability(unit_type)
	if result == Err.OK:
		for res in Globals.Resources.values():
			ai_resources[res] -= Globals.unit_cost[unit_type][res]
			resource_count_updated.emit(Globals.Teams.AI, res, ai_resources[res])
		unit_purchased.emit(unit_type)
	
	return result

func get_available_units() -> Array:
	var available_units : Array = []
	for unit_type in Globals.Units:
		var check : Err = check_availability(unit_type)
		if check == Err.OK:
			available_units.append(unit_type)
	
	return available_units

func check_availability(unit_type : Globals.Units) -> Err:
	var result : int = 0
	if purchase_cooldown_timers[unit_type] > 0:
		return Err.COOLDOWN
	if unit_count[unit_type] >= Globals.max_units[unit_type]:
		return Err.MAX_REACHED
	for res in Globals.Resources.values():
		if ai_resources[res] < Globals.unit_cost[unit_type][res]:
			result += 1 << res
	if result > 0:
		return result as Err
		
	return Err.OK

func set_priority():
	pass
		
func _on_unit_spawned(unit_type : Globals.Units):
	unit_count["Total"] += 1
	unit_count[unit_type] += 1

func _on_unit_died(unit_type : Globals.Units):
	unit_count["Total"] -= 1
	unit_count[unit_type] -= 1

func _on_resource_unloaded(amount : int, resource_type : Globals.Resources):
	ai_resources[resource_type] += amount
	resource_count_updated.emit(Globals.Teams.AI, resource_type, ai_resources[resource_type])

