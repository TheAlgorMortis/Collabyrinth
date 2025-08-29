extends Control


#---------------------------------------------#
#                  Signals                    #
#---------------------------------------------#
#------------------------------------------------------------------------------#


signal play
signal multi
signal settings
signal exit


#---------------------------------------------#
#                 Constants                   #
#---------------------------------------------#
#------------------------------------------------------------------------------#


const BUTTON = preload("res://UIs/MazeButton/maze_button.tscn")
const BUTTONS = ["SOLO", "COLLAB", "SETTINGS", "EXIT"]


#---------------------------------------------#
#                  Globals                    #
#---------------------------------------------#
#------------------------------------------------------------------------------#


var SIGNALS = {"SOLO":play, "COLLAB":multi, "SETTINGS":settings, "EXIT":exit}
var buttons= []
var prev_mouse_pos:Vector2
var cur_mouse_pos
var started = false


#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# Generate a background for the screen.
func generate(res_x=get_viewport().size.x, res_y=get_viewport().size.y):
	$Backdrop.generate_from_dims(res_x, res_y)
	$Backdrop.set_color(20,0,45)
	cur_mouse_pos = get_viewport().get_mouse_position()
	started = true
		
	var base_anchor = 1.0 / (BUTTONS.size()+0.5)
	var top_anchor = base_anchor / 2

	# Generate buttons dynamically
	for id in range(BUTTONS.size()):
		var cur_button = BUTTON.instantiate()
		var cur_control = Control.new()
		cur_control.add_child(cur_button)
		$Overall/Buttons.add_child(cur_control)
		cur_button.gen_button(1,5, BUTTONS[id].to_upper())
		cur_button.position = -cur_button.size / 2
		cur_control.scale *= 2
		
		cur_control.anchor_top = top_anchor
		top_anchor += base_anchor

		cur_button.clicked.connect(button_signal)
		buttons.append(cur_button)


# Called when the node enters the scene tree for the first time.
func _ready():
	generate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if started:
		prev_mouse_pos = cur_mouse_pos
		cur_mouse_pos = get_viewport().get_mouse_position()
		var move_dir = cur_mouse_pos-prev_mouse_pos
		if move_dir != Vector2(0,0):
			$Backdrop.nudge(move_dir)


# emits the signal of a clicked button
func button_signal(btn_name:String):
	SIGNALS.get(btn_name).emit()


# Sets the visibility of all buttons
func set_button_visibility(vis=true):
	$Overall/Buttons.visible = vis


# Sets the visibility of the collabyrinth title
func set_title_visibility(vis=true):
	$Overall/Control.visible=vis
