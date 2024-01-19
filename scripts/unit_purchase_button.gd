extends TextureButton
class_name UnitPurchaseButton

@export var unit_type : Globals.Units
@export var hud : CanvasLayer
@onready var cooldown_effect: TextureProgressBar = $CooldownEffect
@onready var label: Label = $Panel/Label

var cooldown_time : float
var current_time : float

func _ready() -> void:
	set_process(false)
	mouse_entered.connect(hud._on_unit_purchase_button_hovered.bind(self))
	mouse_exited.connect(hud._on_unit_purchase_button_unhovered)
	texture_normal.region.position.x = unit_type * 48
	texture_pressed.region.position.x = unit_type * 48
	texture_hover.region.position.x = unit_type * 48
	texture_disabled.region.position.x = unit_type * 48
	texture_focused.region.position.x = unit_type * 48

	cooldown_time = Globals.purchase_cooldowns[unit_type]
	cooldown_effect.max_value = cooldown_time
	label.text = "Wood: %d\nStone: %d" % [Globals.unit_cost[unit_type][Globals.Resources.WOOD], Globals.unit_cost[unit_type][Globals.Resources.STONE]]

func _process(delta: float) -> void:
	current_time -= delta
	cooldown_effect.value = current_time
	if current_time <= 0:
		disabled = false

func start_cooldown() -> void:
	current_time = cooldown_time
	cooldown_effect.value = current_time
	disabled = true
	set_process(true)


func _on_mouse_entered() -> void:
	$Panel.show()


func _on_mouse_exited() -> void:
	$Panel.hide()
