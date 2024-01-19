extends Label

var crit : bool = false
var target_font_size : int = 32

func _ready() -> void:
	if crit:
		target_font_size = 64
		label_settings.font_color = Color.RED
	var tw = create_tween().set_parallel()
	tw.finished.connect(queue_free)
	tw.tween_property(self, "label_settings:font_size", target_font_size, 0.25)
	tw.tween_property(self, "position:y", position.y -48, 0.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	


