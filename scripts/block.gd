extends Control

const base_pitch: float = 0.6

enum states {DEFAULT, READY, WRONG, CORRECT, HALF_CORRECT}

@export var tint_grey: Color
@export var tint_green: Color
@export var tint_yellow: Color
@export var tint_white: Color

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label
@onready var border: TextureRect = $Border
@onready var flip_sound: AudioStreamPlayer = $FlipSound
@onready var anim: AnimationPlayer = $AnimationPlayer

var state: int = states.DEFAULT


func change_visibility(c: bool, l: bool, b: bool):
	color_rect.visible = c
	label.visible = l
	border.visible = b


func change_color(c: Color, l: Color, b: Color):
	color_rect.color = c
	label.label_settings.font_color = l
	border.modulate = b


func _ready():
	SignalBus.game_started.connect(refresh_state)


func update_state():
	match state:
		states.DEFAULT:
			change_color(tint_grey, tint_grey, tint_grey)
			change_visibility(false, false, true)
		states.READY:
			change_color(tint_white, tint_grey, tint_grey)
			change_visibility(true, true, true)
		states.WRONG:
			change_color(tint_grey, tint_white, tint_grey)
			change_visibility(true, true, false)
		states.CORRECT:
			change_color(tint_green, tint_white, tint_grey)
			change_visibility(true, true, false)
		states.HALF_CORRECT:
			change_color(tint_yellow, tint_white, tint_grey)
			change_visibility(true, true, false)


func refresh_state():
	state = states.DEFAULT
	update_state()
	anim.play("RESET")
