extends Control


var d_lab
var c_lab
var b_lab
var r_lab
var d_slider
var c_slider
var b_slider
var r_slider
var maze

# Called when the node enters the scene tree for the first time.
func _ready():
	
	d_lab = $HBoxContainer/Panel/MarginContainer/VBoxContainer/d_hbox/d_lab
	c_lab = $HBoxContainer/Panel/MarginContainer/VBoxContainer/c_hbox/c_lab
	b_lab = $HBoxContainer/Panel/MarginContainer/VBoxContainer/b_hbox/b_lab
	r_lab = $HBoxContainer/Panel/MarginContainer/VBoxContainer/r_hbox/r_lab
	d_slider = $HBoxContainer/Panel/MarginContainer/VBoxContainer/d_hbox/d_slider
	c_slider = $HBoxContainer/Panel/MarginContainer/VBoxContainer/c_hbox/c_slider
	b_slider = $HBoxContainer/Panel/MarginContainer/VBoxContainer/b_hbox/b_slider
	r_slider = $HBoxContainer/Panel/MarginContainer/VBoxContainer/r_hbox/r_slider
	maze = $HBoxContainer/Panel2/TrimmedMaze


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_d_slider_value_changed(value):
	d_lab.text = str(d_slider.value)
func _on_c_scalar_value_changed(value):
	c_lab.text = str(c_slider.value)
func _on_b_slider_value_changed(value):
	b_lab.text = str(b_slider.value)
func _on_r_slider_value_changed(value):
	r_lab.text = str(r_slider.value)


func _on_start_button_button_down():
	var d_scale = float(d_slider.value) / 100
	var c_scale = float(c_slider.value) / 100
	var b_scale = float(b_slider.value) / 100
	var r_scale = float(r_slider.value) / 100
	var d = $HBoxContainer/Panel/MarginContainer/VBoxContainer/dims_hbox/dims_spin.value
	
	#var maze_dict = AM.generate_maze(2, d, d_scale, c_scale, b_scale, r_scale)
	var maze_dict = AM.generate_prims(d)
	maze.build_from_dict(maze_dict)
	maze.produce()
	maze.set_window(d,d)
	maze.start_game()
	
	
		#load_maze_from_file()
	#produce()
	#set_axis_collabyrinth(C.AXIS_Y, 2)
	##set_window(5,5)
	#scale *=2
	#start_game()

	
	
	
	
	
	
	
	
	
