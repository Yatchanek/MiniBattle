extends CanvasLayer

@onready var blue_team_score: Label = $Control/HBoxContainer/BlueTeamScore
@onready var red_team_score: Label = $Control/HBoxContainer/RedTeamScore
@onready var player_resource_count: VBoxContainer = $Control/ResourceCounters/PlayerResources/PlayerResourceCount
@onready var ai_resource_count: VBoxContainer = $Control/ResourceCounters/AIResources/AIResourceCount

var resource_counters : Array 

func _ready() -> void:
	Globals.resource_count_updated.connect(_on_resource_count_updated)
	resource_counters = [player_resource_count, ai_resource_count]
	update_all_resources()

func update_score(team : Globals.Teams, value : int):
	var target_tabel = blue_team_score if team == Globals.Teams.PLAYER else red_team_score
	target_tabel.text = str(value)

func _on_resource_count_updated(team : Globals.Teams, resource_type : Globals.Resources, amount : int):
	var target_label : Label = resource_counters[team].get_child(resource_type).get_child(1)
	target_label.text = str(amount)
	
func update_all_resources():
	for resource_type in Globals.resource_count[Globals.Teams.PLAYER].keys():
		var target_label : Label = resource_counters[Globals.Teams.PLAYER].get_child(resource_type).get_child(1)
		target_label.text = str(Globals.resource_count[Globals.Teams.PLAYER][resource_type])
	for resource_type in Globals.resource_count[Globals.Teams.AI].keys():
		var target_label : Label = resource_counters[Globals.Teams.AI].get_child(resource_type).get_child(1)
		target_label.text = str(Globals.resource_count[Globals.Teams.AI][resource_type])
