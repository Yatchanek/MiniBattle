extends TextureProgressBar

func update_value(_value : int, _max : int):
	var percentage = float(_value) / float(_max) * 100
	value = percentage

