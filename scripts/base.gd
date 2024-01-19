extends Node2D
class_name  Base

@export var world : Node2D
@export var max_hp : int
@export var defense : int
@export var team : Globals.Teams

@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var label_spawn_point: Marker2D = $LabelSpawnPoint
@onready var sprite: Sprite2D = $Sprite2D

var current_hp : int

var width : int

signal hit(damage : int, pos : Vector2)

func _ready() -> void:
	width = sprite.texture.get_width() * 0.5
	current_hp = max_hp
	if team == Globals.Teams.PLAYER:
		hitbox.collision_layer = 256
		hitbox.collision_mask = 8
		
	else:
		hitbox.collision_layer = 512
		hitbox.collision_mask = 4
		$Sprite2D.region_rect.position.x = 148

func take_damage(attacker : CombatUnit):
	var damage = attacker.attack_power - defense
	var crit : bool = randf() < attacker.crit_chance
	if crit:
		damage = ceil(damage * 1.5)	
	current_hp -= damage
	hit.emit(damage, label_spawn_point.global_position, crit)
	var health_percentage : float = float(current_hp) / float(max_hp) * 100
	update_health_bar(health_percentage)
	if health_percentage < 33:
		$Sprite2D.region_rect.position.y = 236
	elif health_percentage < 50:
		$Sprite2D.region_rect.position.y = 118
	
	
func update_health_bar(value : float):
	if value < 100:
		health_bar.show()
	health_bar.value = value
	health_bar.tint_progress = Color.GREEN
	if value < 33:
		health_bar.tint_progress = Color.RED
	elif value < 66:
		health_bar.tint_progress = Color.YELLOW
	
func _on_hitbox_area_entered(area: Area2D) -> void:
	take_damage(area.attacker)


