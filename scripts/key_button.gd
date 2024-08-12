extends Label

enum states {DEFAULT, READY, WRONG, CORRECT, HALF_CORRECT}

@onready var button = $TextureButton
@onready var anim = $AnimationPlayer

@export var tint_grey: Color
@export var tint_green: Color
@export var tint_yellow: Color
@export var tint_white: Color

var state: int = states.DEFAULT


func _ready():
	SignalBus.game_started.connect(refresh_state)
	SignalBus.row_finished.connect(change_state)


func refresh_state():
	state = states.DEFAULT
	update_visuals()


# give priority in the order correct>half_correct>wrong when changing state
# lock the state if the state is already met in the given priority order
func change_state(c_list: Array, h_list: Array, w_list: Array):
	if text.to_lower() in c_list or state == states.CORRECT:
		state = states.CORRECT
		update_visuals()
		return
	elif text.to_lower() in h_list or state == states.HALF_CORRECT:
		state = states.HALF_CORRECT
		update_visuals()
		return
	elif text.to_lower() in w_list or state == states.WRONG:
		state = states.WRONG
		update_visuals()
		return


func update_visuals():
	match state:
		states.DEFAULT:
			label_settings.font_color = tint_grey
			button.modulate = tint_white
		states.CORRECT:
			label_settings.font_color = tint_white
			button.modulate = tint_green
		states.HALF_CORRECT:
			label_settings.font_color = tint_white
			button.modulate = tint_yellow
		states.WRONG:
			label_settings.font_color = tint_white
			button.modulate = tint_grey


func _on_button_pressed():
	SignalBus.virtual_key_pressed.emit(text)
	anim.stop()
	anim.play("squish")


func _on_button_mouse_entered():
	button.modulate.a = 0.7


func _on_button_mouse_exited():
	button.modulate.a = 1.0
