extends Unit
class_name CombatUnit

@onready var health_bar: TextureProgressBar = $HealthBar
#@onready var sprite_2d: Sprite2D = $Pivot/Sprite2D
@onready var label_spawn_position: Marker2D = $LabelSpawnPosition
@onready var enemy_detector: Area2D = $Pivot/EnemyDetector
@onready var friendly_unit_detector: Area2D = $Pivot/FriendlyUnitDetector
@onready var pivot: Marker2D = $Pivot
@onready var enemy_detector_collision_shape: CollisionShape2D = $Pivot/EnemyDetector/EnemyDetectorCollisionShape
@onready var friendly_detector_collision_shape: CollisionShape2D = $Pivot/FriendlyUnitDetector/FriendlyDetectorCollisionShape
@onready var body: Area2D = $Body

var direction : int
var target : Unit

var is_boosted : bool
var attacking_base : bool = false
var boost_duration : float = 30.0

##Current Stats
var max_hp : int
var current_hp : int
var attack_power : int
var attack_charge_duration : float
var crit_chance : float
var defense : int
var evasion : float

#Temporary stats for boost
var _attack_power : int
var _attack_charge_duration : float
var _crit_chance : float
var _defense : int
var _evasion : float

signal enemy_detected(_target : Unit)
signal attack(_attacker : Unit)


func _ready() -> void:
	super()
	is_boosted = false
	#ready.connect(Globals._on_unit_spawned.bind(self))
	body.area_entered.connect(_on_body_area_entered)
	spawn_label.connect(get_parent()._on_unit_hit)
	sprite_2d.scale = Vector2.ZERO
	sprite_2d.flip_h = direction < 0
	initialize_stats()
	health_bar.update_value(current_hp, max_hp)
	
	if team == Globals.Teams.PLAYER:
		direction = 1
		body.collision_layer = 1
		body.collision_mask = 8
		enemy_detector.collision_mask = 2 + 512
		friendly_unit_detector.collision_mask = 1
		sprite_2d.modulate = Color.WHITE
	else:
		direction = -1
		body.collision_layer = 2
		body.collision_mask = 4
		enemy_detector.collision_mask = 1 + 256
		friendly_unit_detector.collision_mask = 2
		sprite_2d.modulate = Color.SALMON
		
	pivot.scale.x = direction
	enemy_detector_collision_shape.shape.size.x = unit_data.attack_range - unit_data.sprite_width * 0.5	
	enemy_detector.position.x = unit_data.sprite_width * 0.5 + enemy_detector_collision_shape.shape.size.x * 0.5

	friendly_unit_detector.position.x = unit_data.proximity_range

	var tw = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(sprite_2d, "scale", Vector2.ONE, 0.25)
	await  tw.finished
	switch_state(States.MOVE)
	
func _process(delta: float) -> void:
	if is_boosted:
		boost_duration -= delta
		if boost_duration <= 0:
			remove_boost()
			is_boosted = false
			sprite_2d.material.set_shader_parameter("color", Color(0, 0, 0, 0))
	
	if current_state == States.MOVE:
		velocity = Vector2.RIGHT * unit_data.move_speed * direction
		position +=  velocity * delta

func initialize_stats():
	for property in unit_data.mutable_properties:
		set(property, randi_range(unit_data.min_max_stats["min_" + property],unit_data.min_max_stats["max_" + property] ))
	for property in unit_data.mutable_float_properties:
		set(property, snappedf(randf_range(unit_data.min_max_stats["min_" + property],unit_data.min_max_stats["max_" + property]), 0.01))
	
	current_hp = max_hp

	
func boost():
	_attack_power = attack_power
	_attack_charge_duration = attack_charge_duration
	_defense = defense
	_evasion = evasion
	_crit_chance = crit_chance
	
	attack_power = ceil(attack_power * 1.25)
	attack_charge_duration *= 1.2
	defense = ceil(defense * 1.2)
	evasion *= 0.8
	crit_chance *= 1.25
	
	
	spawn_label.emit(0, label_spawn_position.global_position, "Boost!")
	sprite_2d.material.set_shader_parameter("color", Color.GREEN)
	is_boosted = true
	boost_duration = 30.0

func remove_boost():	
	attack_power = _attack_power
	attack_charge_duration = _attack_charge_duration
	defense = _defense
	evasion = _evasion
	crit_chance = _crit_chance
	sprite_2d.material.set_shader_parameter("color", Color(0, 0, 0, 0))
	is_boosted = false

func stop():
	target = null
	switch_state(States.MOVE)

func prepare_to_attack():
	animation_player.speed_scale = 1 / attack_charge_duration
	animation_player.play("PrepareAttack")

func attack_target():
	animation_player.play("Attack")

func check_for_target():
	if get_enemies_in_range_count() > 0:
		animation_player.play("PrepareAttack")
	else:
		pass		

func calculate_received_damage(power : int, _crit_ch : float) -> Array:
	var received_damage : int
	var crit : bool = false
	if randf() < evasion:
		received_damage = -1
	else:
		received_damage = max(1, ceil((power - defense) * randf_range(0.8, 1.2)))
		crit = randf() < _crit_ch
		
	if crit:
		received_damage = ceil(received_damage * 1.5)
		
	return [received_damage, crit]

func take_damage(attacker : CombatUnit) -> void:
	var damage_data : Array = calculate_received_damage(attacker.attack_power, attacker.crit_chance)
	var damage = damage_data[0]
	var crit : bool = damage_data[1]
	spawn_label.emit(damage, label_spawn_position.global_position, crit)
	
	if damage >= 0:
		current_hp -= damage
		health_bar.update_value(current_hp,max_hp)

	if current_hp <= 0.0:
		die()
		
func die():
	pivot.hide()
	animation_player.call_deferred("pause")
	set_process(false)
	body.get_node("CollisionShape2D").set_deferred("disabled", true)
	var tw = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.finished.connect(queue_free)
	tw.tween_property(sprite_2d, "scale", Vector2.ZERO, 0.5)

func _on_death_animation_finished():
	died.emit()	

func _on_enemy_detector_area_entered(area: UnitBody) -> void:
	switch_state(States.FIGHT)
	if area.get_parent() is Base:
		attacking_base = true
		
func get_enemies_in_range_count() -> int:
	return enemy_detector.get_overlapping_areas().size()

func _on_friendly_unit_detector_area_entered(area: UnitBody) -> void:
	if self is RangedUnit:
		return
	if unit_data.unit_type == area.body_owner.unit_data.unit_type and not area.get_parent().attacking_base:
		switch_state(States.IDLE)

func _on_enemy_detector_area_exited(_area: UnitBody) -> void:
	if get_enemies_in_range_count() == 0:
		target = null
		switch_state(States.MOVE)

func _on_friendly_unit_detector_area_exited(_area: UnitBody) -> void:
	if current_state != States.FIGHT:
		switch_state(States.MOVE)

func _on_body_area_entered(area: Area2D) -> void:
	take_damage(area.attacker)
	if area is Projectile:
		area.queue_free()


