extends Control

const MAX_WORD_LENGTH: int = 5
const alphabet_list: Array[String] = [
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
	'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
]
const music_volume: float = -6.0
const rot_speed: float = 4.0
const arrow_speed: float = 2.0
const counter_speed: float = 0.6
const counter_scale: float = 1.2
const error_speed: float = 2.0
const error_scale: float = 1.2
const color_speed: float = 0.5
const wipe_speed: float = 1.0

@onready var guesses: VBoxContainer = $Guesses
@onready var error_box: Label = $ErrorBox
@onready var error_timer: Timer = $TimerGroup/ErrorTimer
@onready var restart_timer: Timer = $TimerGroup/RestartTimer
@onready var rounds_text: Label = $RoundsText
@onready var wins_text: Label = $WinsText
@onready var shape: TextureRect = $VisualsGroup/Shape
@onready var shape_2: TextureRect = $VisualsGroup/Shape2
@onready var shape_3: TextureRect = $VisualsGroup/Shape3
@onready var shape_4: TextureRect = $VisualsGroup/Shape4
@onready var mod_color: ColorRect = $VisualsGroup/Modulate
@onready var arrow_left_anchor: Control = $ArrowLeftAnchor
@onready var arrow_right_anchor: Control = $ArrowRightAnchor
@onready var keyboard: Control = $Keyboard
@onready var info: Label = $Info
@onready var more_button: TextureButton = $MoreButton
@onready var relax_timer: Timer = $TimerGroup/RelaxTimer
@onready var wipe: ColorRect = $VisualsGroup/Wipe
@onready var mute_button: TextureButton = $MuteButton

@onready var music: AudioStreamPlayer = $AudioGroup/Music
@onready var type_sound: AudioStreamPlayer = $AudioGroup/TypeSound
@onready var error_sound: AudioStreamPlayer = $AudioGroup/ErrorSound
@onready var delete_sound: AudioStreamPlayer = $AudioGroup/DeleteSound
@onready var win_sound: AudioStreamPlayer = $AudioGroup/WinSound
@onready var confirm_sound: AudioStreamPlayer = $AudioGroup/ConfirmSound
@onready var lose_sound: AudioStreamPlayer = $AudioGroup/LoseSound

var word_list: Array[String]
var word: String
var max_guesses: int
var arrow_tween: Tween

var can_type: bool = true
var can_check_info: bool = true
var current_block: int = 0
var current_row: int = 0
var round_count: int = 1
var win_count: int = 0


# code for starting a round
func initialize_round():
	SignalBus.game_started.emit()
	pick_new_word()
	if round_count > 1:
		tween_round_counter()
		reset_arrows()
	
	error_box.hide()
	max_guesses = guesses.get_child_count()
	rounds_text.text = str(round_count)
	current_block = 0
	current_row = 0
	can_type = true
	can_check_info = true


# pick new word
func pick_new_word():
	word = word_list.pick_random()
	#print(word)


# type a letter into the current block of the current row
func type_letter(letter: String):
	if current_block < MAX_WORD_LENGTH:
		var block = guesses.get_child(current_row).get_child(current_block)
		block.label.text = letter
		block.state = block.states.READY
		block.anim.play("scale_up")
		current_block += 1
		type_sound.play()


# erase the letter in the previous block of the current row
func erase_letter():
	if current_block > 0:
		current_block -= 1
		var block = guesses.get_child(current_row).get_child(current_block)
		block.label.text = ""
		block.state = block.states.DEFAULT
		block.anim.play("scale_down")
		delete_sound.play()


# display error message
func show_error(message: String, sound: AudioStreamPlayer = error_sound):
	error_box.text = message
	error_box.show()
	error_box.pivot_offset.x = error_box.size.x / 2.0
	error_timer.start()
	sound.play()
	var error_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT
		).set_trans(Tween.TRANS_CUBIC)
	error_tween.tween_property(error_box, "scale", Vector2.ONE, 1/error_speed
		).from(Vector2(error_scale, error_scale))


# combine the letters and return the result
func get_guess():
	var row = guesses.get_child(current_row)
	var guess: String
	for block in row.get_children():
		guess += block.label.text
	return guess.to_lower()


# shows the result for each block of the current row 
func confirm_answer():
	# error check
	if current_block < MAX_WORD_LENGTH:
		show_error("Not enough letters")
		return
	elif not get_guess() in word_list:
		show_error("Not in word list")
		return
	
	can_type = false
	can_check_info = false
	var row = guesses.get_child(current_row)
	confirm_sound.play()
	
	# create a copy of the word; used to prevent repeated confirmation of half-correct(yellow) letters 
	var word_copy = word
	
	# to send to virtual keys
	var c_list = []
	var h_list = []
	var w_list = []
	
	# check which letters are correct, blank them from word_copy
	for block in row.get_children():
		if block.label.text.to_lower() == word[block.get_index()]:
			block.state = block.states.CORRECT
			c_list.append(block.label.text.to_lower())
			word_copy[block.get_index()] = " "
	
	# check which letters half-correct, blank them from word_copy
	for block in row.get_children():
		if block.label.text.to_lower() in word_copy and not block.state == block.states.CORRECT:
			block.state = block.states.HALF_CORRECT
			h_list.append(block.label.text.to_lower())
			var letter_index = word_copy.findn(block.label.text, 0)
			word_copy[letter_index] = " "
	
	# the rest of the letters are wrong
	for block in row.get_children():
		if block.state == block.states.READY:
			block.state = block.states.WRONG
			w_list.append(block.label.text.to_lower())
	
	# play flip animtion for each letter
	for block in row.get_children():
		block.anim.play("flip")
		await block.anim.animation_finished
	
	# update keys in virtual keyboard
	SignalBus.row_finished.emit(c_list, h_list, w_list)
	
	# check if round was either won or lost
	if get_guess() == word:
		win_round()
	elif current_row == max_guesses - 1:
		lose_round()
	else:
		current_row += 1
		current_block = 0
		can_type = true
		can_check_info = true
		tween_arrows()


func lose_round():
	round_count += 1
	lose_sound.play()
	show_error(word.to_upper(), lose_sound)
	restart_timer.start()


func win_round():
	show_error("Great Job!", win_sound)
	restart_timer.start()
	round_count += 1
	win_count += 1
	tween_win_counter()
	change_background_color()
	wins_text.text = str(win_count)
	wins_text.show()
	win_sound.play()


func tween_arrows():
	var next_pos = guesses.get_child(current_row).global_position.y
	arrow_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT
		).set_trans(Tween.TRANS_CUBIC).set_parallel()
	arrow_tween.tween_property(arrow_left_anchor, "position:y", next_pos, 1/arrow_speed)
	arrow_tween.tween_property(arrow_right_anchor, "position:y", next_pos, 1/arrow_speed)


func reset_arrows():
	if arrow_tween:
		arrow_tween.kill()
	var next_pos = guesses.get_child(0).global_position.y
	arrow_left_anchor.position.y = next_pos
	arrow_right_anchor.position.y = next_pos


func tween_round_counter():
	var counter_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT
		).set_trans(Tween.TRANS_QUINT).set_parallel()
		
	counter_tween.tween_property(rounds_text, "scale", Vector2.ONE, 1/counter_speed
		).from(Vector2(counter_scale, counter_scale))
	counter_tween.tween_property(shape, "scale", Vector2.ONE, 1/counter_speed
		).from(Vector2(counter_scale, counter_scale))


func tween_win_counter():
	var counter_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT
		).set_trans(Tween.TRANS_QUINT).set_parallel()
	
	counter_tween.tween_property(wins_text, "scale", Vector2.ONE, 1/counter_speed
		).from(Vector2(counter_scale, counter_scale))
	counter_tween.tween_property(shape_2, "scale", Vector2.ONE, 1/counter_speed
		).from(Vector2(counter_scale, counter_scale))


func tween_wipe():
	wipe.show()
	var wipe_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT
		).set_trans(Tween.TRANS_QUINT)
	wipe_tween.tween_property(wipe, "size:y", 0, 1/wipe_speed)
	await wipe_tween.finished
	wipe.hide()


func change_background_color():
	var new_color = Color.from_hsv(randf(), 1.0, 1.0, 0.25)
	var mod_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT
		).set_trans(Tween.TRANS_SINE)
	mod_tween.tween_property(mod_color, "color", new_color, 1/color_speed)


func _ready():
	# feel free to add more words if needed, simply add the word to the bottom of the text file
	if FileAccess.file_exists("res://assets/word_list.txt"):
		var file = FileAccess.open("res://assets/word_list.txt", FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line()
			if not line in word_list:
				word_list.append(line.to_lower())
		file.close()
	
	music.volume_db = music_volume
	initialize_round()
	tween_wipe()
	wins_text.hide()
	
	SignalBus.virtual_key_pressed.connect(virtual_key_received)
	SignalBus.virtual_enter_pressed.connect(virtual_enter_received)
	SignalBus.virtual_back_pressed.connect(virtual_back_received)


# for visuals only
func _process(delta):
	shape.rotation_degrees += rot_speed * delta
	shape_2.rotation_degrees += rot_speed * delta
	shape_3.rotation_degrees += rot_speed * delta
	shape_4.rotation_degrees -= rot_speed * delta


# check for any keyboard input
# ignore the input if it is held down (ie. no echo)
# input must be an English letter
func _unhandled_key_input(event):
	if can_type:
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			var key_input = OS.get_keycode_string(event.key_label)
			# can only quit application if in editor
			if event.is_action_pressed("quit") and OS.has_feature("editor"):
				get_tree().quit()
			if event.is_action_pressed("erase"):
				erase_letter()
			if event.is_action_pressed("confirm"):
				confirm_answer()
			if key_input in alphabet_list:
				type_letter(key_input)


func virtual_key_received(char: String):
	if can_type:
		type_letter(char)


func virtual_enter_received():
	if can_type:
		confirm_answer()


func virtual_back_received():
	if can_type:
		erase_letter()


func _on_more_button_pressed():
	if can_check_info:
		info.visible = not info.visible
		can_type = not can_type
		confirm_sound.play()


func _on_mute_button_pressed():
	confirm_sound.play()
	if mute_button.is_mute:
		music.volume_db = -80
	else:
		music.volume_db = music_volume


func _on_error_timer_timeout():
	error_box.hide()


func _on_restart_timer_timeout():
	initialize_round()


func _on_relax_timer_timeout():
	music.play()


func _on_music_finished():
	relax_timer.start()
