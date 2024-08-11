extends TextureButton

@onready var anim: AnimationPlayer = $AnimationPlayer


func _on_mouse_entered():
	modulate.a = 0.7


func _on_mouse_exited():
	modulate.a = 1.0


func _on_pressed():
	anim.stop()
	anim.play("squish")
