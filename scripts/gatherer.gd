extends Unit
class_name Gatherer

@export var max_capacity : int
@export var base : Node2D


@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var pivot: Marker2D = $Pivot
@onready var tool: Sprite2D = $Pivot/Tool
@onready var detector: Area2D = $Pivot/Detector

signal resource_unloaded(amount : int, _team : Globals.Teams)

var current_amount : float
var forage_progress : float
var target : Node2D
var target_position : Vector2
var forage_type : Globals.Resources

func _ready() -> void:
	super()
	add_to_group("Gatherers")
	if team == Globals.Teams.PLAYER:
		detector.collision_mask = 32 + 64
		resource_unloaded.connect(Globals._on_resource_unloaded)
	else:
		detector.collision_mask = 32 + 128
		resource_unloaded.connect(AIControler._on_resource_unloaded)
	if forage_type == Globals.Resources.STONE:
		tool.region_rect.position.y = 20
	forage_progress = 0
	current_state = States.IDLE
	await get_tree().create_timer(0.25).timeout
	choose_resource()
	go_foraging()

func _physics_process(delta: float) -> void:
	if current_state == States.MOVE:
		if is_instance_valid(target):
			var next_path_position = nav_agent.get_next_path_position()
			var dir : Vector2 = (next_path_position - global_position).normalized()
			if dir.x != 0:
				pivot.scale.x = sign(dir.x)
			velocity = dir * unit_data.move_speed
			position += velocity * delta
		else:
			choose_resource()
			go_foraging()
		
	elif current_state == States.FORAGE:
		if is_instance_valid(target):
			forage_progress += delta
			if forage_progress >= unit_data.work_speed:
				animation_player.play("Work")
				forage_progress = 0
		elif current_amount < unit_data.max_capacity:
			go_foraging()
		else: 
			go_to_base()

	elif current_state == States.UNLOAD:
		forage_progress += delta
		if forage_progress >= unit_data.work_speed:
			var amount_removed : int = min(unit_data.unload_efficiency, current_amount)
			if amount_removed == 0:
				choose_resource()
				go_foraging()
			else:
				current_amount -= amount_removed
				#if current_amount == 0:
					#
					#go_foraging()
			resource_unloaded.emit(amount_removed, forage_type)
			forage_progress = 0

func collect(amount : int) -> int:
	if amount > unit_data.max_capacity - current_amount:
		amount = unit_data.max_capacity - current_amount
	current_amount += amount
	if current_amount >= unit_data.max_capacity:
		go_to_base()
	return amount

func choose_resource():
	var priority : float
	if team == Globals.Teams.PLAYER:
		priority = Globals.player_gathering_priority
	else:
		priority = AIControler.gathering_priority
	if randf() < (1 - priority):
		forage_type = Globals.Resources.WOOD
	else:
		forage_type = Globals.Resources.STONE

func recheck():
	if current_state == States.MOVE:
		go_foraging()
			
func find_closest_site(_forage_type : Globals.Resources):
	var sites : Array
	if _forage_type == Globals.Resources.WOOD:
		sites = get_tree().get_nodes_in_group("Trees")
	else:
		sites = get_tree().get_nodes_in_group("GoldMines")
	var closest_site : ResourceArea
	var closest_dist : float = INF
	
	for site in sites:
		var dist = global_position.distance_squared_to(site.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_site = site
	
	if closest_site:
		return closest_site
	else:
		return null	
	
func go_to_base():
	target = base
	nav_agent.target_position = target.global_position
	switch_state(States.MOVE)

func go_foraging():
	target = find_closest_site(forage_type)
	if is_instance_valid(target):
		if global_position.x < target.global_position.x:
			nav_agent.target_position = target.global_position + Vector2(-target.width, randf_range(-target.height * 0.75, target.height * 0.75))
		else:
			nav_agent.target_position = target.global_position + Vector2(target.width, randf_range(-target.height * 0.75, target.height * 0.75))
		switch_state(States.MOVE)
	else:
		switch_state(States.IDLE)
	

func _on_area_2d_area_entered(area: Area2D) -> void:
	var site = area.get_parent() as ResourceArea
	if site == target:
		if forage_type == Globals.Resources.STONE:
			tool.region_rect.position.y = 20
		else:
			tool.region_rect.position.y = 0
		switch_state(States.FORAGE)
	elif area.get_parent() is Vault:
		switch_state(States.UNLOAD)
