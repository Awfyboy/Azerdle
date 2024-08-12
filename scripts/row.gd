extends HBoxContainer


func _ready():
	for block in get_children():
		block.flip_sound.pitch_scale = block.base_pitch + (0.1 * block.get_index())
