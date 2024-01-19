extends CanvasLayer

@onready var player_resource_count: VBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/VBoxContainer/PlayerResources/PlayerResourceCount
@onready var ai_resource_count: VBoxContainer = $Control/AIResources/AIResourceCount

var resource_counters : Array


func _ready() -> void:
	Globals.resource_count_updated.connect(_on_resource_count_updated)
	AIControler.resource_count_updated.connect(_on_resource_count_updated)
	resource_counters = [player_resource_count, ai_resource_count]
	update_all_resources()

func _on_resource_count_updated(team : Globals.Teams, resource_type : Globals.Resources, amount : int):
	var target_label : Label = resource_counters[team].get_child(resource_type).get_child(1)
	target_label.text = str(amount)
	
func update_all_resources():
	for resource_type in Globals.player_resources.keys():
		var target_label : Label = resource_counters[Globals.Teams.PLAYER].get_child(resource_type).get_child(1)
		target_label.text = str(Globals.player_resources[resource_type])
	for resource_type in AIControler.ai_resources.keys():
		var target_label : Label = resource_counters[Globals.Teams.AI].get_child(resource_type).get_child(1)
		target_label.text = str(AIControler.ai_resources[resource_type])

func configure_panel(unit_type : Globals.Units):
	%UnitNameLabel.text = Globals.unit_names[unit_type]
	if unit_type != Globals.Units.GATHERER:
		%AttackLabel.text = "%d-%d" % [Globals.unit_stats[unit_type]["min_attack_power"], Globals.unit_stats[unit_type]["max_attack_power"]]
		%DefenseLabel.text = "%d-%d" % [Globals.unit_stats[unit_type]["min_defense"], Globals.unit_stats[unit_type]["max_defense"]]
		%MaxHpLabel.text = "%d-%d" % [Globals.unit_stats[unit_type]["min_max_hp"], Globals.unit_stats[unit_type]["max_max_hp"]]
		%EvasionLabel.text = "%.2f-%.2f" % [Globals.unit_stats[unit_type]["min_evasion"], Globals.unit_stats[unit_type]["max_evasion"]]
		%AttackChargeLabel.text = "%.2f-%.2f" % [Globals.unit_stats[unit_type]["min_attack_charge_duration"], Globals.unit_stats[unit_type]["max_attack_charge_duration"]]
		%Stats.show()
	else:
		%Stats.hide()
	%WoodCostLabel.text = "Wood: %d" % Globals.unit_cost[unit_type][Globals.Resources.WOOD]
	%StoneCostLabel.text = "Stone: %d " % Globals.unit_cost[unit_type][Globals.Resources.STONE]

func _on_unit_purchase_button_hovered(button : UnitPurchaseButton):
	configure_panel(button.unit_type)
	%UnitInfoPanel.show()
	
func _on_unit_purchase_button_unhovered():
	%UnitInfoPanel.hide()
	

func _on_priority_slider_value_changed(value: float) -> void:
	Globals.player_gathering_priority = value
