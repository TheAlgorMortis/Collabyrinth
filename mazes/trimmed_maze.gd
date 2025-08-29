extends Control

'''
A trimmed maze is a Basic maze that can be clipped to windows of specific sizes.
This allows the player to see smaller windows of the maze that smoothly scroll with the player,
So that the player will always be visible inside the window and the window will always be
completely filled by the maze.
'''


#---------------------------------------------#
#                 Variables                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

var cs
var rs
var maze_pos:Vector2
@onready var basic_maze = $Container/BasicMaze
@onready var maze_border = $Container/MazeBorder

var cur_curtain_size:Vector2
var window_size:Vector2

signal exited

#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Called when the node enters the scene tree for the first time.

func _ready():
	# Set a reference
	
	# THESE SHOULD BE COMMENTED OUT - ONLY IN FOR TESTING
	load_maze_from_file()
	produce()
	set_window(5,3)
	start_game()
	pass


# Generate the window for the trimmed maze,
# given the number of visible rows and columns.
func set_window(cols:int, rows:int):
	$Container.scale = Vector2(1,1)
	# Getting current diameter of the maze
	var cur_dia = basic_maze.get_dia()
	
	# rows and cols cannot be bigger than diameter
	rs = rows if rows < cur_dia else cur_dia
	cs = cols if cols < cur_dia else cur_dia

	var parent_size = get_parent().size
	window_size = Vector2(cs, rs) * C.CELL_AREA
	$Container.custom_minimum_size = window_size
	$Container/Curtain.custom_minimum_size = window_size

	$Container.anchor_left = 0.5
	$Container.anchor_top = 0.5
	$Container.anchor_right = 0.5
	$Container.anchor_bottom = 0.5

	# Set the pivot (optional if using anchors)
	$Container.pivot_offset = $Container.size / 2
	
	if rs > cs:
		$Container.scale *= parent_size.y / (rs * C.CELL_AREA)
	else:
		$Container.scale *= parent_size.x / (cs * C.CELL_AREA)
		

	# Getting player indices in the maze
	var player_indices_vector = basic_maze.get_player_indices_vector()

	# The player should be centered in the given window,
	# Which mean the left position should be the player position
	# - window_size /2
	var maze_left_indices = player_indices_vector - (Vector2(int(cs/2), int(rs / 2)))
	
	# Making sure that the edge of the maze stays smugly on the screen
	if maze_left_indices.x < 0:
		maze_left_indices.x = 0
	elif maze_left_indices.x + cs > cur_dia:
		maze_left_indices.x = cur_dia - cs
		
	if maze_left_indices.y < 0: 
		maze_left_indices.y = 0
	elif maze_left_indices.y + rs > cur_dia:
		maze_left_indices.y = cur_dia - rs



	# Shift the left of the maze to the correct 
	basic_maze.reposition_on_index(maze_left_indices.x, maze_left_indices.y)

	# Set maze moves directions for first moves
	set_maze_moves()
	
	# SETTING UP THE MAZE BORDER
	maze_border.generate_border(rs, cs)
	maze_border.position = basic_maze.position -Vector2(-maze_left_indices.x,-maze_left_indices.y) * C.CELL_AREA

# Given the player position, determine whether the maze should move
# for each direction the player can choose.
func set_maze_moves():
	
	var p_pos = basic_maze.get_player_indices_vector()
	var maze_dia = basic_maze.get_dia()
	basic_maze.reset_maze_moves()
	
	var r_rad = rs/2
	var r_rem = rs - r_rad
	var c_rad = cs/2
	var c_rem = cs - c_rad
	
	if p_pos.x > c_rad and p_pos.x <= maze_dia - c_rem:
		basic_maze.set_maze_moves(C.DIR_LEFT, true)
		
	if p_pos.x >= c_rad and p_pos.x < maze_dia - c_rem:
		basic_maze.set_maze_moves(C.DIR_RIGHT, true)
		
	if p_pos.y > r_rad and p_pos.y <= maze_dia - r_rem:
		basic_maze.set_maze_moves(C.DIR_UP, true)
		
	if p_pos.y >= r_rad and p_pos.y < maze_dia - r_rem:
		basic_maze.set_maze_moves(C.DIR_DOWN, true)


# Call the above method each time the player has finished moving.
func _on_basic_maze_moved():
	set_maze_moves()

# Set the allowed move direcitons of this maze
func set_allowed_move_dirs(legal_move_dirs):
	basic_maze.set_allowed_move_dirs(legal_move_dirs)

# Set the maze to be an axis collabyrinth (ie, a maze where you can only
# see in one dimension)
func set_axis_collabyrinth(axis=C.AXIS_X, radius=2):
	# Only allowing the player to move on their axis.
	var axis_dir = C.AXES_DICT[axis]
	set_allowed_move_dirs(axis_dir)
	# Get the window size given the axis.
	# We get the unit vector for the movement direction so that we multiply
	# only the correct direction by the diameter.
	# the diameter is given as 2*radius for the direction of the radius in either direction
	# plus one, for the player position
	# we plus (1,1) to do the +1 mentioned above, and also give the other axis
	# a width of 1, so that the player can only see that line.
	var diameter_vector = (axis_dir[C.AXES_MAG_INDEX] * (2 * radius)) + Vector2(1,1)
	set_window(diameter_vector.x, diameter_vector.y)


@rpc("any_peer","call_local")
func load_maze_from_file(filepath="res://MazeTexts/tester.txt"):
	print("here we still good")
	basic_maze.load_maze_from_file(filepath)


func start_game():
	open_curtain()
	basic_maze.activate()


func pause_game():
	basic_maze.deactivate()


func produce():
	basic_maze.produce_maze()


func build_from_dict(maze_dict):
	$Container/BasicMaze.load_maze_from_dict(maze_dict)


func open_curtain():
	var dir
	if rs < cs:
		dir = C.DIR_UP * rs * C.CELL_AREA
	else:
		dir = C.DIR_LEFT * cs * C.CELL_AREA
	shift_curtain(dir)
		
func close_curtain():
	var dir
	if rs < cs:
		dir = C.DIR_DOWN * rs * C.CELL_AREA
	else:
		dir = C.DIR_RIGHT * cs * C.CELL_AREA
	shift_curtain(dir)
	
	
func shift_curtain(dir, interval=50):
	dir /= interval
	for i in range(interval):
		$Container/Curtain.custom_minimum_size += dir
		await get_tree().create_timer(1 / interval).timeout
	


func _on_basic_maze_exited():
	close_curtain()
	exited.emit()
