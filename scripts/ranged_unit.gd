extends CombatUnit
class_name RangedUnit

@onready var projectile_spawn_position: Marker2D = $Pivot/ProjectileSpawnPosition
@onready var bow: Sprite2D = $Pivot/Bow

var projectile_scene = preload("res://scenes/projectile.tscn")

signal projectile_fired(projectile : Projectile)


func _ready() -> void:
	super()
	projectile_fired.connect(get_parent()._on_projectile_fired)

func die():
	bow.hide()
	super()

func launch_projectile():
	var pr : Projectile = projectile_scene.instantiate() as Projectile
	pr.attacker = self
	pr.initialize(self, direction, team, projectile_spawn_position.global_position)
	projectile_fired.emit(pr)
		
#func prepare_to_attack():
	#animation_player.play("PrepareAttack")
#
#func attack_target():
	#animation_player.play("Attack")
