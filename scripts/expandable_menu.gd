extends Control


@onready var buttons: Array = $ExpandableMenu/Buttons.get_children()
@onready var info_panel: Panel = $InfoPanel
@onready var texture_rect: TextureRect = $ExpandableMenu/TextureRect
@onready var button_area: GridContainer = $ExpandableMenu/Buttons

var tw : Tween
var direction : int
var button_area_rect : Rect2
var trigger_area_rect : Rect2

func _ready() -> void:
	for button in buttons:
		button.modulate.a = 0
		button.disabled = true
		button.mouse_default_cursor_shape = CURSOR_ARROW
	texture_rect.mouse_exited.connect(_on_mouse_exited.bind(texture_rect))
	button_area.mouse_exited.connect(_on_mouse_exited.bind(button_area))
	
	await get_tree().process_frame
	button_area_rect = button_area.get_global_rect()
	button_area_rect = button_area_rect.grow_individual(10.0, 0.0, 0.0, 0.0)
	trigger_area_rect = texture_rect.get_global_rect()
	trigger_area_rect = trigger_area_rect.grow_individual(0.0, 0.0, 10.0, 0.0)
	
func _on_texture_rect_mouse_entered() -> void:
	if tw:
		tw.kill()
	tw = create_tween()
	var idx : int = 0
	direction = 1
	var target_modulation : float = 1.0	#buttons[idx].mouse_default_cursor_shape = CURSOR_POINTING_HAND
	for i in range(idx, buttons.size()):
		tw.tween_property(buttons[i], "modulate:a", target_modulation, 0.025)
		buttons[i].disabled = false
		buttons[i].mouse_default_cursor_shape = CURSOR_POINTING_HAND

func _on_mouse_exited(node : Control) -> void:
	if (node == texture_rect and button_area_rect.has_point(get_global_mouse_position())) \
	or (node == button_area and trigger_area_rect.has_point(get_global_mouse_position())):
		return
	if tw:
		tw.kill()
		
	tw = create_tween()
	var idx : int = buttons.size() - 1
	var target_modulation : float = 0.0
	for i in range(buttons.size() - 1, -1, -1):
		tw.chain().tween_property(buttons[i], "modulate:a", target_modulation, 0.02)
		buttons[i].disabled = true
		buttons[i].mouse_default_cursor_shape = CURSOR_ARROW
	
	info_panel.hide()

func _on_button_hovered(button : UnitPurchaseButton):

	if button.modulate.a < 1.0:
		return
	info_panel.global_position = calculate_panel_position(button)
	set_panel_text(button)
	info_panel.show()
	
func _on_button_unhovered():
	info_panel.hide()

func set_panel_text(button : UnitPurchaseButton):
	$InfoPanel/Label.text = "%s\nWood: %d\nStone: %d" % [Globals.unit_names[button.unit_type], Globals.unit_cost[button.unit_type][Globals.Resources.WOOD], Globals.unit_cost[button.unit_type][Globals.Resources.STONE]]
	
func calculate_panel_position(button : UnitPurchaseButton):
	var pos : Vector2 
	var button_rect : Rect2 = button.get_global_rect()
	pos.x = button_area_rect.position.x + button_area_rect.size.x + 8
	pos.y = button_rect.position.y - (info_panel.size.y - button_rect.size.y) * 0.5
	return pos
