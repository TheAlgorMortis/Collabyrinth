extends Node2D

'''
The basic maze is the first level of abstraction
It is intended to serve as a parent for all of the obstacle types.
'''

#---------------------------------------------#
#                  Signals                    #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Signal emitted when the maze has moved.
# Primarily used for trimmed mazes
signal moved
signal exited


#---------------------------------------------#
#                 Globals                     #
#---------------------------------------------#

@onready var abstract_maze = $AbstractMaze
@onready var player = $Par/Player
@onready var backdrop_container = $Par/Container
@onready var backdrop = $par/Container/Backdrop
@onready var obstacles = $par/ObstacleParent

# whether the maze is active
var active = false
# whether the player is moving into the exit
var exiting = false

# Maze Movement
var maze_move_dir:Vector2
var nudge_vector:Vector2
var final_position:Vector2

# The player's position, as an index.
var player_indices_vector:Vector2 = C.NULL_VECTOR

# The obstacles in the ObstacleParent layer, as a matrix
var phys_obstacles:Array = []

# The current obstacle opposing the player.
# Used to store information for bumps.
var _current_obstacle

# Whether there is an obstacle before the player
var _do_obstacle_bump:bool = false

# Whether the maze moves when the player moves
var maze_moves:bool = false

# size
var size

# Whether the maze should move when a player moves in a specific direction.
var maze_moves_dirs:Dictionary = {
		C.DIR_UP    : false,
		C.DIR_DOWN  : false,
		C.DIR_LEFT  : false,
		C.DIR_RIGHT : false
	}

# A set of directions that the player is allowed to move in.
# This is mainly used for direction constraining in multiplayer
var allowed_move_dirs = {
		C.DIR_UP    : true,
		C.DIR_DOWN  : true,
		C.DIR_LEFT  : true,
		C.DIR_RIGHT : true
	}


#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Called when the node enters the scene tree for the first time.
func _ready():
	#load_maze_from_file()
	#produce_maze()
	#activate()
	pass


#---------------------------------------------#
#               The game loop                 #
#---------------------------------------------#


# called on each tick. Listens for player moves (The game loop)
func _process(delta):
	if active:
		# Only act if the player is not already in a movement sequence.
		if not $Player.is_moving:
			# Check if the player has entered move input.
			var move_dir = get_move_dir()
			if move_dir != C.NULL_VECTOR:
				# Only perform the move if its allowed
				if allowed_move_dirs[move_dir]:
					# The rpc makes this so that
					# all the players that are connected move in that same direction
					# ie, the character moves in a synchonized manner.
					moves.rpc(move_dir)


#---------------------------------------------#
#          Creating and Loading mazes         #
#---------------------------------------------#


# Read a maze from file using the abstract maze,
# then use it to set up the graphical playable maze.
# The string default is a tester maze
# RIGHT NOW THIS ONLY SUPPORTS 2D MAZES
func load_maze_from_file(filepath:String="res://MazeTexts/tester.txt"):
	# Loading the maze as an abstract maze
	$AbstractMaze.build_from_file(filepath)
	
	# Only moving forward if its a 2D maze
	if $AbstractMaze.get_dims() != 2:
		print("Warning! THIS IS NOT A 2D MAZE")


# Build a maze from a maze dictionary
func load_maze_from_dict(maze_dict):
	$AbstractMaze.build_from_dict(maze_dict)
	
	# Only moving forward if its a 2D maze
	if $AbstractMaze.get_dims() != 2:
		print("Warning! THIS IS NOT A 2D MAZE")


# Once an abstract maze is set up, this is used to produce the actual game maze.
func produce_maze():
	
		
	# Getting the container size for making the backdrop
	var pixel_maze_size = $AbstractMaze.get_dia() * C.CELL_AREA
	$Container.custom_minimum_size = Vector2(pixel_maze_size, pixel_maze_size)

	# Generating the backdrop for the maze, using the given the diameter
	$Container/Backdrop.generate_for_maze($AbstractMaze.get_dia())

	# Building obstacles
	_create_obstacles()

	# Place the player in the correct location.
	_position_player()
		
		
		


# Set up the player position, scale, an position vector to be used throughout the game
func _position_player():
	# Get the position of the maze player (usually will be the same as the start pos
	var player_indices_array = $AbstractMaze.get_unq_pos(C.ENT_PLAYER)
	# Get the player's posisition ito maze index vector
	player_indices_vector = _array_to_vector(player_indices_array)
	# now position the player in terms of pixels.
	_reposition_element($Player, player_indices_vector)
	$Player.do_idle()


# Given an abstract obstacle type and maze indices,
# Generate the phyiscal obstacle and place it in the correct spot.
func _create_obstacles():
	$ObstacleParent.position = Vector2(0,0)
	# Getting the cells array from the abstract maze
	var cells = $AbstractMaze.get_cells()
	purge()
		
	# Loop through rows
	for row_pos in range($AbstractMaze.get_dia()):
		# Add a new empty row to the maze
		phys_obstacles.append([])
		# loop through columns
		for col_pos in range($AbstractMaze.get_dia()):
			# Create the new obstacle and append it to the end of the row (ie at the column pos)
			# [row_pos, col_pos] := [y,x]
			# Get the obstacle type at the position
			
			var cell_pos = [col_pos, row_pos]
			
			var cell_dict = $AbstractMaze.get_cell_node(cell_pos)
			
			var this_obstacle = C.ELEMENT_SCENES.get(cell_dict[C.MC_OBS]).instantiate()
			# Add the child to the obstacle parent layer.
			$ObstacleParent.add_child(this_obstacle)
			# place the obstace in the correct position.
			var pos_vector = _array_to_vector(cell_pos)
			# Place the obstacle where its supposed to be.
			_reposition_element(this_obstacle, pos_vector)
			# add the borders to the obstacle if it is solio
			if  C.IS_SOLID[cell_dict[C.MC_OBS]]:
				#print("adding borders for " + str(cell_pos))
				_add_borders(this_obstacle, cell_pos, cell_dict[C.MC_NEIGHBOURS])
			# Add it to the phys_obstacle list for taking note
			phys_obstacles[row_pos].append(this_obstacle)


# Reposition an element
# Given a vector with the indices of the element relative to the array,
# Now repositioned in terms of its pixel position.
func _reposition_element(element, indices:Vector2):
	# Done by setting its position its index multiplied by the size of a
	# cell of the maze
	element.position = indices * C.CELL_AREA


# Filter through the maze and add borders through the necessary walls
func _add_borders(solid, cell_pos, non_solid_neighbours):
	#print("Neighbours: " + str(non_solid_neighbours))
	var cell_vec = _array_to_vector(cell_pos)
	# loop through the neigbours that are not solid
	for non_solid_neighbour in non_solid_neighbours:
		# Get the indices as vectors
		var dir_vec = _array_to_vector(non_solid_neighbour) - cell_vec
		# Use the vectors to add the border to the obstacle
		solid.add_border(dir_vec)


func activate():
	active = true
	
func deactivate():
	active = false


#---------------------------------------------#
#                 Helpers                     #
#---------------------------------------------#


# Converts an array position into a vector position
# Arrays usually have the y position first, which is why it goes 1 0 and not 0 1
func _array_to_vector(arr:Array):
	return Vector2(arr[1], arr[0])


# Converts an vector position into an array position
# Arrays usually have the y position first, which is why it goes y x and not x y
func _vector_to_array(vec:Vector2):
	return [vec.y, vec.x]


# Determines if the given position is within the borders of the maze.
func _within_border(pos:Vector2):
	if (pos.x < 0) or (pos.y < 0) or (pos.x >= $AbstractMaze.get_dia()) or (pos.y >= $AbstractMaze.get_dia()):
		return false
	else:
		return true


#---------------------------------------------#
#                Movement                     #
#---------------------------------------------#


# facilitates moves and bumps. Is called on every tick in the game loop.
@rpc("any_peer", "call_local")
func moves(move_dir):
	# Orient the player according to the attempted movement direction
	$Player.reorient(move_dir)

	# Move the player if they are not obstructed / out of bounds
	if can_move(move_dir):
		# Determine if the maze should move.
		# This is used for maze clipping in trimmed mazes.
		maze_moves = maze_moves_dirs.get(move_dir)
		if maze_moves:
			_prepare_maze_movement(move_dir)

		# Check if the player is exiting.
		exiting = $AbstractMaze.get_cell_node(_vector_to_array(player_indices_vector))[C.MC_OBS] == C.OBS_END

		# Move the player.
		# The 2nd arg prevents the player from actually moving if 
		# he maze is moving.
		$Player.move(move_dir, not maze_moves, exiting)

	# Otherwise, the player bumps into whatever obstacle it faces.
	else:
		# Bump the player.
		$Player.bump(move_dir)
		# If a specific obstancle is bumped, bump that obstacle.
		if _do_obstacle_bump:
			_current_obstacle.bump(move_dir)


# Read player input and convert it into a directional unit vector
func get_move_dir():
	for move_str in C.DIRECTIONS.keys():
		if Input.is_action_just_pressed(move_str):
			return C.DIRECTIONS.get(move_str)
	# if none of the directions
	return C.NULL_VECTOR


# Determine whether the player can move in the given direction
# (True - can move; False - can bump)
func can_move(move_dir:Vector2):
	# find the indices for the proposed new position
	var new_indices_vec = player_indices_vector + move_dir
	var new_indices_arr = _vector_to_array(new_indices_vec)
	# Get the indices for the player pos
	var cur_indices = _vector_to_array(player_indices_vector)
	# Get the cell node for that pos
	var cell_node = $AbstractMaze.get_cell_node(cur_indices)
	# If the new pos is non-solid, we can move there, otherwise not.
	
	if not _within_border(new_indices_vec):
		_do_obstacle_bump = false
		return false

	
	#print("New indices: " + str(new_indices_arr) + " neighbours: " + str(cell_node[C.MC_NEIGHBOURS]))
	for possible_new in cell_node[C.MC_NEIGHBOURS]:
		if C.arr_equal(new_indices_arr, possible_new):
			player_indices_vector = new_indices_vec 
			return true
	_current_obstacle = phys_obstacles[new_indices_arr[1]][new_indices_arr[0]]
	_do_obstacle_bump = true
	return false


# prepares the maze for movement
func _prepare_maze_movement(move_dir):
	# The move_dir is negated here, because the maze moves
	# against the player.
	maze_move_dir = -move_dir
	# the nudge vector is a global that determines
	# the distance and direction that the maze moves per frame
	nudge_vector = C.NUDGE_DIST * maze_move_dir
	# Determine the final position of the maze
	final_position = $ObstacleParent.position + (maze_move_dir * C.MOVE_DIST)


# Nudges the maze (when the player is nudged)
# Triggered by the player_nudged signal
func _on_player_nudged():
	if maze_moves:
		$ObstacleParent.position += nudge_vector
		# Nudge the backdrop for parralax scrolling
		$Container/Backdrop.nudge(maze_move_dir)


# Asserts the maze final position.
# Is called when the player's final position is asserted
func _on_player_asserted():
	# If the maze moved, set the position to the precalculated final position
	if maze_moves:
		$ObstacleParent.position = final_position
	if exiting:
		deactivate()
		exited.emit()
	else:
		# Emit a signal to confirm that the maze move has been completed.
		moved.emit()


#---------------------------------------------#
#           Trimmed maze use api              #
#---------------------------------------------#


# The next two methods are used by the trimmed maze to set whether the maze
# will move when heading in a given direction.

# Reset the maze moves dict.
# This means that the maze will never move when the player moves.
func reset_maze_moves():
	maze_moves_dirs = {
			C.DIR_UP    : false,
			C.DIR_DOWN  : false,
			C.DIR_LEFT  : false,
			C.DIR_RIGHT : false
		}


# Set whether the maze will move when moving in the given move_dir
func set_maze_moves(move_dir:Vector2, will_move:bool=true):
	maze_moves_dirs[move_dir] = will_move


# Repositioning the maze on indices. This is primarily used in trimmed mazes.
func reposition_on_index(left_index:int, top_index:int):
	position = Vector2(-left_index,-top_index) * C.CELL_AREA


#---------------------------------------------#
#                  Getters                    #
#---------------------------------------------#


# Get the player positon (as index)
func get_player_indices_vector():
	return player_indices_vector


func get_dia():
	return $AbstractMaze.get_dia()


#---------------------------------------------#
#              Property setters               #
#---------------------------------------------#


# Contrain the allowed directions of motion
func set_allowed_move_dirs(legal_move_dirs):
	for move_dir in allowed_move_dirs:
		# if each move dir is in the given options, set it to true
		# otherwise set it to false.
		allowed_move_dirs[move_dir] = true if move_dir in legal_move_dirs else false


#---------------------------------------------#
#                 Clearing                    #
#---------------------------------------------#

# annihilate the maze
func purge():
	for obstacle_row in phys_obstacles:
		for obstacle in obstacle_row:
			obstacle.queue_free()
	phys_obstacles = []
	
