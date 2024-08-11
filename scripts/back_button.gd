extends Label

@onready var button = $TextureButton
@onready var anim = $AnimationPlayer


func _on_button_pressed():
	SignalBus.virtual_back_pressed.emit()
	anim.stop()
	anim.play("squish")


func _on_button_mouse_entered():
	button.modulate.a = 0.7


func _on_button_mouse_exited():
	button.modulate.a = 1.0
