extends CombatUnit
class_name SupportUnit

@onready var weapon: Sprite2D = $Pivot/Weapon
@onready var timer: Timer = $Timer
@onready var weapon_effect: GPUParticles2D = $Pivot/Weapon/WeaponEffect

var enemies_nearby: Array
var allies_nearby: Array
var wait_cooldown = 1.0

func _ready() -> void:
	super()
	enemy_detector.position.x = 0
	enemy_detector_collision_shape.shape.size.x = unit_data.proximity_range * 2
	friendly_unit_detector.position.x = 0
	friendly_detector_collision_shape.shape.size.x = unit_data.attack_range * 2
	enemies_nearby = []
	timer.wait_time = attack_charge_duration
	timer.start()

func _process(delta: float) -> void:
	super(delta)
	if current_state == States.WAIT:
		wait_cooldown -= delta
		if wait_cooldown <= 0:
			switch_state(States.MOVE)

func die():
	weapon.hide()
	allies_nearby = []
	enemies_nearby = []
	super()
	
func stop():
	super()

func attack_target():
	#allies_nearby = friendly_unit_detector.get_overlapping_areas()
	for i in range(allies_nearby.size() - 1, -1, -1):
		if allies_nearby[i].is_boosted:
			allies_nearby.remove_at(i)

	if allies_nearby.size() > 0:
		animation_player.play("Attack")
	else:
		await get_tree().process_frame
		if is_instance_valid(self):
			timer.start()
			switch_state(previous_state)
		
func cast_spell():
	var unit : Unit = allies_nearby.pick_random()
	if is_instance_valid(unit) and not unit.is_boosted:
		unit.boost()
	else:
		allies_nearby.erase(unit)
		if allies_nearby.size() > 0:
			cast_spell()
		else:
			return
	weapon_effect.emitting = true
	
func resume():
	timer.start()
	switch_state(previous_state)	

func _on_enemy_detector_area_entered(area: Area2D) -> void:
	if area.get_parent() is Base:
		switch_state(States.IDLE)
	else:
		enemies_nearby.append(area)
		if direction == pivot.scale.x:
			direction = -direction
	
func _on_enemy_detector_area_exited(area: Area2D) -> void:
	enemies_nearby.erase(area)
	if enemies_nearby.size() == 0:
		if direction != pivot.scale.x:
			direction = -direction
			switch_state(States.WAIT)
			wait_cooldown = 1.0
	
func _on_friendly_unit_detector_area_entered(area: UnitBody) -> void:
	if area.body_owner == self:
		return
	if unit_data.unit_type == area.body_owner.unit_data.unit_type:
		switch_state(States.IDLE)
	allies_nearby.append(area.body_owner)

	
func _on_friendly_unit_detector_area_exited(area: UnitBody) -> void:
	if current_state != States.FIGHT:
		switch_state(States.MOVE)
	allies_nearby.erase(area.body_owner)

func _on_body_area_entered(area: Area2D) -> void:
	take_damage(area.attack_power)
	if area is Projectile:
		area.queue_free()

func _on_timer_timeout() -> void:
	switch_state(States.CAST)
