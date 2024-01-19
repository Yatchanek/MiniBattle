extends Area2D
class_name Projectile

@export var speed : int
@export var lifetime : float

var attack_power : int
var direction : int
var velocity : Vector2
var attacker : Unit

func initialize(_attacker : Unit, dir : int,team : Globals.Teams, pos : Vector2):
	attacker = _attacker
	direction = dir
	scale.x = direction
	velocity = Vector2.RIGHT * direction * speed
	if team == Globals.Teams.PLAYER:
		collision_layer = 4
	else:
		collision_layer = 8
	global_position = pos
	
func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

