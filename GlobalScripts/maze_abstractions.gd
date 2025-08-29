extends Node


var cur_maze = {}
var traversal_pos




#---------------------------------------------#
#               Maze Reading                  #
#---------------------------------------------#
#-------------------------------------------------------------------------------

# Reading and constructing a maze from a given text file
func build_from_file(file_name:String):
	
	# Initialize a maze dict
	cur_maze = {}
	
	# Open the file
	var maze_file = FileAccess.open(file_name, FileAccess.READ)
	
	# Emit a signal if there is a failure 
	if not maze_file:
		return
	

	# Set the dimensions and the diameter of the maze
	_set_nd(int(maze_file.get_line().strip_edges()), int(maze_file.get_line().strip_edges()))
	
	# Prepare the traversal_pos to keep track of the position during maze reading
	_init_traversal()
		
	cur_maze[C.AM_REQ_UNQ_POS] = {}
	
	# Build the obstacles from the file 
	cur_maze[C.AM_CELLS] = _build_maze(maze_file, cur_maze[C.AM_N])
	


	# Verify that the maze has a start, end and player
	for req_unq in C.REQUIRED_AS_UNIQUE:
		if not cur_maze[C.AM_REQ_UNQ_POS].has(req_unq):
			emit_signal("invalid_maze_file","Missing element of type " + req_unq)
			print("Missing element of type " + req_unq)

	# Set all non-solid neighbours for use in graph operations
	set_all_neighbours()
	
	# close the maze file.
	maze_file.close()
	
	return cur_maze


# Recursively builds a maze from a file.
# This can build a maze of any dimension >= 1
# defaults to the entire maze dimension (for the call on the entire maze)
# THIS ULTIMATELY MEANS THAT THE INNERMOST ARRAY WILL BE THE X DIRECTION
# Since rows are built last, and rows are the x direction
# That means vectors for indices should be built in reverse
func _build_maze(maze_file, n, trav_ind=0):
	# Produce the obstacle list for this layer.

	# Base case: If we have reduced to 1st dimension, generate the cell line.
	if n == 1:
		return _gen_cell_line(maze_file.get_line().strip_edges(), trav_ind)

	# Otherwise, continue reducing to the 1st dimension
	else: 
		# Initialize a list
		# This list represents an n-dimensional hyperplane, containing
		# d (n-1)-dimensional hyperplanes
		var cells = []
		# Iterate through the diameter
		_set_traversal_zeros(trav_ind)
		for i in range(cur_maze[C.AM_D]):
			# for each hyperplace, build the n-1 dims.
			# also, pass the hyperplane's traversal pos
			cells.append(_build_maze(maze_file, n-1, trav_ind+1))
			# increment the position in this direction of the hyperplane
			traversal_pos[trav_ind] += 1
		# Return the n-dimensional hyperplane
		return cells


# Takes a line from the text file - a one-dimensional line of the maze, and 
# builds it's array.
# trav_ind should be the index of the x axis in the traversal pos array
func _gen_cell_line(obstacle_line:String, trav_ind):
	var cell_string = obstacle_line.split("|",false)
	# fail if the cell line does not meet the maze diameter
	if cell_string.size() != cur_maze[C.AM_D]:
		emit_signal("invalid_maze_file","line length does not match maze diameter")
		print("An obstacle line does not match the maze diameter")
		return
		
	# set the initial pos in the x direction to 0
	_set_traversal_zeros(trav_ind)
	
	# create a cells list (these act as nodes in a graph)
	var cells = []
	# Start generating the graph dict items for these cells
	for cell in cell_string:
		print("At pos " + str(traversal_pos) + " there is " + cell)
		
		# split cell into its obstacle and entity.
		var contents = cell.split(":")
		
		# Extract the obstacle
		var obs = contents[C.TI_OBS]
		# generate the node
		cells.append(_init_cell_dict(obs))
		# If the obstacle is required as unique:
		if obs in C.REQUIRED_AS_UNIQUE:
			# Check if it already exists, otherwise error.
			if cur_maze[C.AM_REQ_UNQ_POS].has(obs):
				emit_signal("invalid_maze_file","duplicate element of type " + obs)
				print("duplicate element of type " + obs)
				return
			# note that and save its position.
			cur_maze[C.AM_REQ_UNQ_POS][obs] = traversal_pos.duplicate(true)
			print("added obstacle of type " + obs)
			
		# If there is an entity, handle it here.
		if contents.size() == C.TI_LENGTH:
			var ent = contents[C.TI_ENT]
			# If the entity is required as unique:
			if ent in C.REQUIRED_AS_UNIQUE:
				# Check if it already exists, otherwise error.
				if cur_maze[C.AM_REQ_UNQ_POS].has(ent):
					emit_signal("invalid_maze_file","duplicate element of type " + ent)
					print("duplicate element of type " + ent)
					return
				# note that and save its position.
				cur_maze[C.AM_REQ_UNQ_POS][ent] = traversal_pos.duplicate(true)
				print("added entity of type " + ent)
				
		
		# move to the next position.
		traversal_pos[trav_ind] += 1
		
	# return the line of cells.
	return cells


#------------------------------------------------------------------------------#
#---------------------------------------------#
#               Maze generation               #
#---------------------------------------------#
#------------------------------------------------------------------------------#

#---------------------------------------------#
#                   DFS                       #
#---------------------------------------------#

var dfs_directions
var end_pos
var end_dist

# Generate a 2-dimensional maze using a Depth-First-Search Algorithm.
func generate_dfs(d:int):
	# Init the maze dict
	cur_maze = {}
	
	# Init the dimensions and diameter
	_set_nd(2, d)
	
	# Turn the maze into an empty n-hypercube
	cur_maze[C.AM_CELLS] = _init_empty_maze(2, C.OBS_WALL)
	
	# Generate a starting position at an even index
	var start_pos = _produce_random_even_position()
	
	# Set the obstacle type of the start to Air.
	change_cell_obs_type(get_cell_node(start_pos), C.OBS_AIR)
	
	end_dist = 0
	dfs_directions = C.DIRECTIONS_2.values()
	
	carve_dfs(start_pos, 0)
	change_cell_obs_type(get_cell_node(start_pos), C.OBS_START)
	change_cell_obs_type(get_cell_node(end_pos), C.OBS_END)
	
		# Generating the req_unq dict
	cur_maze[C.AM_REQ_UNQ_POS] = {C.OBS_START: start_pos, C.ENT_PLAYER: start_pos, C.OBS_END: end_pos}

	# Add edges
	set_all_neighbours()
	
	# Return the carved out maze
	return cur_maze


# Carve a path according to the DFS algorithm.
func carve_dfs(position, distance):
	print("Carving...")
	# Shuffle directions.
	dfs_directions.shuffle()
	# Loop through directions.
	var extended = false
	for direction in dfs_directions:
		# Get the new position in this direction.
		var new_pos = C.arr_add(position, _vector_to_array(direction))
		# If it is a wall in the maze, carve it out. 
		if (0 <= new_pos[0]) and (new_pos[0] < cur_maze[C.AM_D]) and (0 <= new_pos[1]) and (new_pos[1] < cur_maze[C.AM_D]) and C.IS_SOLID[get_cell_node(new_pos)[C.MC_OBS]]:
			change_cell_obs_type(get_cell_node(new_pos), C.OBS_AIR)
			var inter_pod =  C.arr_add(position, _vector_to_array(direction / 2))
			change_cell_obs_type(get_cell_node(inter_pod), C.OBS_AIR)
			carve_dfs(new_pos, distance + 1)
			extended = true
	# If we are at the end of a tunnel and this tunnel has the furthest distance from the start, place the exit here.
	if not extended:
		if distance > end_dist:
			end_dist = distance
			end_pos = position

# Converts an vector position into an array position
# Arrays usually have the y position first, which is why it goes y x and not x y
func _vector_to_array(vec:Vector2):
	return [vec.y, vec.x]

# Converts an array position into a vector position
# Arrays usually have the y position first, which is why it goes 1 0 and not 0 1
func _array_to_vector(arr:Array):
	return Vector2(arr[1], arr[0])

#---------------------------------------------#
#                  Prims                      #
#---------------------------------------------#

var prim_directions

func generate_prims(d:int):
	# Init the maze dict
	cur_maze = {}
	# Init the dimensions and diameter
	_set_nd(2, d)
	# Turn the maze into an empty n-hypercube
	cur_maze[C.AM_CELLS] = _init_empty_maze(2, C.OBS_WALL)
	# Generate a starting position at an even index
	var start_pos = _produce_random_even_position() 
	
	# Set the obstacle type of the start to Air.
	change_cell_obs_type(get_cell_node(start_pos), C.OBS_AIR)
	
	end_dist = 0
	prim_directions = C.DIRECTIONS_2.values()
	
	# Initializing prims algorithm
	var walls = []
	for direction in prim_directions:
		# Get the new position in this direction.
		var new_pos = C.arr_add(start_pos, _vector_to_array(direction))
		var half_pos = C.arr_add(start_pos, _vector_to_array(direction/2))
		# If it is a wall in the maze, carve it out. 
		if (0 <= new_pos[0]) and (new_pos[0] < cur_maze[C.AM_D]) and (0 <= new_pos[1]) and (new_pos[1] < cur_maze[C.AM_D]):
			walls.append([new_pos, half_pos, direction, 2])
			
	var tot_dist = 0
	
	while walls.size() != 0:
		walls.shuffle()
		var cur = walls.pop_back();
		var new_pos = cur[0]
		var half_pos = cur[1]
		var last_dir = cur[2]
		var distance_from_start = cur[3]
		if C.IS_SOLID[get_cell_node(new_pos)[C.MC_OBS]]:
			change_cell_obs_type(get_cell_node(new_pos), C.OBS_AIR)
			change_cell_obs_type(get_cell_node(half_pos), C.OBS_AIR)
			
			# Try to move the exit as far from the start as possible.
			if (distance_from_start > tot_dist):
				tot_dist = distance_from_start
				end_pos = new_pos
			
			prim_directions.erase(last_dir)
			prim_directions.shuffle()
			prim_directions.push_back(last_dir)
			var can_traverse = false
			for direction in prim_directions:
				# We only want to keep going straight IF THERES NO OTHER CHOICE
				# how can i actually determine that here? Because we dont know until th ether
				# walls are processed whether this is an option or not.
				if (direction == last_dir) and (!can_traverse):
					if (randf() > 0.10):
						continue
				
				# Get the new position in this direction.
				var new_pos_2 = C.arr_add(new_pos, _vector_to_array(direction))
				var half_pos_2 = C.arr_add(new_pos, _vector_to_array(direction/2))
				# If it is a wall in the maze, carve it out. 
				if (0 <= new_pos_2[0]) and (new_pos_2[0] < cur_maze[C.AM_D]) and (0 <= new_pos_2[1]) and (new_pos_2[1] < cur_maze[C.AM_D]):
					walls.append([new_pos_2, half_pos_2, direction, distance_from_start+2])
					if C.IS_SOLID[get_cell_node(new_pos_2)[C.MC_OBS]]:
						can_traverse = true
		
		# LOGIC FOR ADDING LOOPS GO HERE!
		#else:
			#if (randf() < 0.01):
				#change_cell_obs_type(get_cell_node(half_pos), C.OBS_AIR)
				

	# change start and end positions to the respective types
	change_cell_obs_type(get_cell_node(start_pos), C.OBS_START)
	change_cell_obs_type(get_cell_node(end_pos), C.OBS_END)
	
	# Generating the req_unq dict
	cur_maze[C.AM_REQ_UNQ_POS] = {C.OBS_START: start_pos, C.ENT_PLAYER: start_pos, C.OBS_END: end_pos}
	# Add edges
	set_all_neighbours()
	
	# Return the carved out maze
	return cur_maze


#---------------------------------------------#
#               Paramaterized                 #
#---------------------------------------------#



func generate_maze(n:int, d:int, d_s=0.5, curve_s=0.5, branch_s=0.5, recon_s=0.5):
	'''
	Generates a complete maze using carve_maze.

	Parameters:
		n: Number of dimensions of the maze.
		d: Diameter (size) of the maze in each dimension.
		d_s: Controls the density of visited cells.
		c_s: Defines how often paths curve.
		b_s: Probability of branching.
		r_s: Probability of reconnections (loops).
	'''
	
	# Init the maze dict
	cur_maze = {}
	
	# Init the dimensions and diameter
	_set_nd(n, d)
	
	# Turn the maze into an empty n-hypercube
	cur_maze[C.AM_CELLS] = _init_empty_maze(n)
	
	# Generate empty visited matrix
	visited = _init_visited(n)
	visited_count = 0
	
	# Generate a starting position at an even index
	var start_pos = _produce_random_even_position()
	
	
	# Generating the req_unq dict
	cur_maze[C.AM_REQ_UNQ_POS] = {C.OBS_START: start_pos, C.ENT_PLAYER: start_pos}

	# Carve out the maze
	carve_maze(start_pos, d_s, curve_s, branch_s, recon_s)
	
	# Set the obstacle type of the start to Start.
	change_cell_obs_type(get_cell_node(start_pos), C.OBS_START)

	# Add edges
	set_all_neighbours()
	
	# Return the carved out maze
	return cur_maze


func _init_empty_maze(n, obs_type=C.OBS_NONE):
	var cells = []
	# if we've reached 1D
	if n == 1:
		# Create a row of cells
		for i in range(cur_maze[C.AM_D]):
			# Initialize a cell node that is rmpty
			cells.append({C.MC_OBS: obs_type, C.MC_NEIGHBOURS:[]})
	# Reduce to 1D
	else:
		for i in range(cur_maze[C.AM_D]):
			cells.append(_init_empty_maze(n-1, obs_type))
	return cells
	

# Change the obstacle type of a cell
func change_cell_obs_type(cell, obs_type=C.OBS_AIR):
	cell[C.MC_OBS] = obs_type


# Generate a random even point in the maze
func _produce_random_even_position():
	randomize()
	var indices = []
	for i in range(cur_maze[C.AM_N]):
		indices.append(generate_even(0, cur_maze[C.AM_D]))
	return indices
	
func _produce_random_odd_position():
	randomize()
	var indices = []
	for i in range(cur_maze[C.AM_N]):
		indices.append(generate_odd(0, cur_maze[C.AM_D]))
	return indices


#----------------------------------#
#           CARVING PATHS          #
#----------------------------------#

var DBG_CARVE = true


# Parameters for maze gen
var max_branch_depth
var max_dead_end_ratio = 0.1
var max_loops = 3

# Tracking for loops and branching
var cur_dead_ends = 0
var cur_loop_count = 0


func carve_maze2(start_pos:Array, d_s:float=0.5, c_s:float=0.5, b_s:float=0.5, r_s:float=0.5):
	'''
	Generates a maze starting from `start_pos` using branching, looping, and curvature controls.

	Parameters:
		d_s: Controls the length of branches and exit placement.
		c_s: Defines how often paths curve.
		b_s: Probability of branching.
		r_s: Probability of reconnections (loops).
	'''
	
	C.dp_title("Maze carving", DBG_CARVE)
	
	# Calculate the total number of cells in the maze
	var total_cells = cur_maze[C.AM_D] ** cur_maze[C.AM_N]
	# Scale branch size
	var max_branch_depth = int(cur_maze[C.AM_D] / 2)
	# Initialze the DFS stack for carving
	var stack = [start_pos]
	# Initialize stack for branch depth
	var branch_depths = [0]
	
	# initialize movement directions.
	_init_directions()
	
	# Perform the DFS maze until the stack is empty
	while stack.size() > 0:
		# Shuffle TOSS for branching probabilites
		shuffle_toss(stack, b_s)
		
		# Get current pos
		var cur_pos = stack.pop_back()
		C.dp("------current pos--------: " + str(cur_pos), DBG_CARVE)
		
		# Get current depth
		var cur_depth = branch_depths.pop_back()
		if cur_depth == null:
			cur_depth = 0
		
		
		# If the current cell has already been visited or is solid, skip it.
		if check_visited(cur_pos) or C.IS_SOLID[get_cell_node(cur_pos)[C.MC_OBS]]:
			continue
		
		# Note that the current position has been visited
		set_visited(cur_pos)
	
		# If we're at an odd position and we reach a probabalistic threshold
		if _is_odd_position(cur_pos) and randf() < 0.3:
			change_cell_obs_type(get_cell_node(cur_pos), C.OBS_WALL)
			# Continue to the next iteration of the loop
			continue

		# Pre-emptively set this cell type to air.
		change_cell_obs_type(get_cell_node(cur_pos), C.OBS_AIR)
		
		# Change direction depending on curvature
		if randf() < c_s:
			_change_dir()
		
		# Get all the valid neighbours
		var neighbours = get_generation_neighbours(cur_pos)
	
		# For looping and reconnections.
		var path_found = false
		
		# loop through neighbours
		for nbr_pos in neighbours:
			C.dp("focus on neighbour: " + str(nbr_pos), DBG_CARVE)
			# Prevent short-cycles
			if will_form_short_cycle(cur_pos, nbr_pos):
				C.dp("Will form short cylce", DBG_CARVE)
				# We ignore this neighbour.
				continue
			
			# Limit branch depth
			if cur_depth < max_branch_depth:
				C.dp("added to stack for this branch", DBG_CARVE)
				stack.append(nbr_pos)
				branch_depths.append(cur_depth + 1)
				set_parent(nbr_pos, cur_pos)
				path_found = true
				
			if not path_found:
				C.dp("Is now a wall.", DBG_CARVE)
				cur_dead_ends += 1
				change_cell_obs_type(get_cell_node(cur_pos), C.OBS_WALL)
				if cur_dead_ends / total_cells > max_dead_end_ratio:
					continue
				if randf() < r_s:
					var nearby_cells = _get_valid_neighbours(cur_pos)
					if nearby_cells.size() > 0:
						var recon_target = C.arr_select_random_element(nearby_cells)
						C.dp("set " + str(recon_target) + " as recon target.", DBG_CARVE)
						stack.append(recon_target)
						set_parent(recon_target, cur_pos)




func carve_maze(start_pos, d_s=0.5, curve_s=0.5, branch_s=0.5, recon_s=0.5):
	# Calculate a target number of cells required to visit
	# based on the number of cells in the maze and the k_scaler
	#var target_path_length = floor((0.33 + 0.33*d_s) * (cur_maze[C.AM_D] ** cur_maze[C.AM_N]))
	# manages carving
	var stack = [start_pos]
	# initialize neighbours directions.
	_init_directions()
	# Loop until the stack is empty
	while stack.size() > 0:
		if randf() < 0.5 * branch_s:
			stack.shuffle()
		var current_pos
		# get the top of the stack
		current_pos = stack.pop_back()
		
		# If the current cell has already been visited or is solid, we skip it.
		if check_visited(current_pos) or C.IS_SOLID[get_cell_node(current_pos)[C.MC_OBS]]:
			continue
		
		# Note that the current position has been visited
		set_visited(current_pos)
	
		# Set this as a wall if it is an odd index
		if _is_odd_position(current_pos):
			change_cell_obs_type(get_cell_node(current_pos), C.OBS_WALL)
			# Continue to the next iteration of the loop
			continue

		# Pre-emptively set this cell type to air.
		change_cell_obs_type(get_cell_node(current_pos))
		
		# Change direction depending on curvature
		if randf() < curve_s:
			_change_dir()
			if randf() < curve_s:
				direction_set.shuffle()
		
		# Get all the valid neighbours of the current position that arent walls
		# (ie might already be air, or still null.)
		var neighbours = get_generation_neighbours(current_pos)
		print("Valid neighbours: " + str(neighbours))
	
		# For looping and reconnections.
		var path_found = false
		
		# loop through neighbours
		for neighbour in neighbours:
			# We want to determine if there might be looping
			# This implies that even at a 100% recon rate there 
			# is only an 70% chance of loops
			var will_loop = randf() < recon_s * 0.8
			if _is_odd_position(neighbour) and not will_loop:
				change_cell_obs_type(get_cell_node(neighbour), C.OBS_WALL)
			else:
				path_found = true
				stack.append(neighbour)
				
		#if we hit a dead end or are at a cross section
		if not path_found:
			change_cell_obs_type(get_cell_node(current_pos), C.OBS_WALL)




#----------------------------------#
#      HANDLING VISITED MATRIX     #
#----------------------------------#

var visited
var visited_count


func _init_visited(n:int) -> Array:
	'''
	RECURSIVE
	Initialize a visited matrix, where each index informs whether the cell has been
	visited during maze gen, and ifso, where it has been visited from.
	
	Parameters:
		n: dimension of the maze
	
	'''
	var vis = []
	# if we've reached 1D
	if n == 1:
		# Create a row of cells
		for i in range(cur_maze[C.AM_D]):
			# Initialize a cell node that is a wall
			vis.append({C.V_BOOL:false, C.V_PARENT:null})
	# Reduce to 1D
	else:
		for i in range(cur_maze[C.AM_D]):
			vis.append(_init_visited(n-1))
	return vis


func check_visited(pos:Array) -> bool:
	'''
	Check if the current position has already been visited
	
	Parameters:
		pos: position to check
	'''
	var cell = visited
	for i in pos:
		cell = cell[i]
	return cell[C.V_BOOL]


func set_visited(pos:Array):
	'''
	Set a given position as visited
	
	Parameters:
		pos: position to set as visited
	'''
	visited_count += 1
	var cell = visited
	for i in pos:
		cell = cell[i]
	cell[C.V_BOOL] = true


func set_parent(pos:Array, parent:Array):
	'''
	Set a given position's parent.
	
	Parameters:
		pos: position to set as visited
		parent: the parent of this position.
	'''
	visited_count += 1
	var cell = visited
	for i in pos:
		cell = cell[i]
	cell[C.V_PARENT] = parent


func get_cell_parent_pos(pos:Array):
	'''
	Return the parent position of the cell
	
	Parameters:
		pos: position whom's parent we want
	'''
	var cell = visited
	for i in pos:
		cell = cell[i]
	return cell[C.V_PARENT]

#----------------------------------#
#        HANDLING DIRECTIONS       #
#----------------------------------#

var direction_set


func _init_directions():
	'''
	Initialize the direction set for the current maze's dimensions
	'''
	# initialize a empty direction set
	direction_set = []
	
	# prepare a null direction
	var direction = []
	for i in range(cur_maze[C.AM_N]):
		direction.append(0)
	
	for i in range(cur_maze[C.AM_N]):
		for j in [-1, 1]:
			var new_dir = direction.duplicate(true)
			new_dir[i] = j
			direction_set.append(new_dir)
	randomize()
	direction_set.shuffle()
	C.dp("direction set: " + str(direction_set), DBG_CARVE)


func _change_dir():
	'''
	Change the top direction in the direction set and shuffle the rest.
	'''
	# pop the bottom direction
	var bottom = direction_set.pop_front()
	# shuffle the remaining
	direction_set.shuffle()
	# push back the bottom to the top
	direction_set.append(bottom)
	C.dp("direction set after dir change: " + str(direction_set), DBG_CARVE)


#----------------------------------#
#        Carving helpers           #
#----------------------------------#

 
func shuffle_toss(stack:Array, b_s:float):
	'''
	Shuffle the top of the DFS stack, depending on b_s.

	Paramters:
		stack: The DFS stack
		b_s: Probability of branching.
	'''

	if randf() < 0.5 * b_s:
		C.dp("stack before shuffle: " + str(stack), DBG_CARVE)
		var segment_size = min(max(5, stack.size()/3), stack.size())
		var TOSS = stack.slice(stack.size() - segment_size)
		TOSS.shuffle()
		for i in range(segment_size):
			# Rebuild the stack
			stack[stack.size() - segment_size + i] = TOSS[i]
		C.dp("stack after shuffle: " + str(stack), DBG_CARVE)


func will_form_short_cycle(cur_pos:Array, nbr_pos:Array) -> bool:
	'''
	Prevents the maze from forming short cycles
	'''
	var temp = nbr_pos
	var path_length = 0
	
	# Backtrack via parent information
	while temp != null:
		if C.arr_equal(temp, cur_pos):
			return path_length <= 3
		temp = get_cell_parent_pos(temp)
		path_length += 1
		if path_length > 5: 
			break
	return false


func get_generation_neighbours(indices:Array):
	'''
	Using the direction set in its current order, return all the neighbours of 
	the given indices that:
		fall within the maze bounds
		are unvisited
		are not solid
	
	Parameters:
		indices: the indices for which we want to find neighbours
		
	Return:
		the pruned set of neighbours
	'''
	var neighbours = []
	for direction in direction_set:
		var new_pos = C.arr_add(direction, indices)
		var valid = true
		for i in range(cur_maze[C.AM_N]):
			if (new_pos[i] < 0) or (new_pos[i] >= cur_maze[C.AM_D]):
				valid = false
				break
		if valid == false:
			continue
		if check_visited(new_pos):
			continue
		if C.IS_SOLID[get_cell_node(new_pos)[C.MC_OBS]]:
			continue
		neighbours.append(new_pos)
	C.dp("Gen neighbours for " + str(indices) + " are: " + str(neighbours), DBG_CARVE)
	return neighbours
	


#----------------------------------#
#           Positioning            #
#----------------------------------#

func _is_odd_position(indices:Array) -> bool:
	'''
	Determine whether indices are odd.
	'''
	for index in indices:
		if index % 2 == 0:
			return false
	return true



func generate_even(lower:int, upper:int) -> int:
	'''
	Generate an even number between two given numbers.
	'''
	var min = lower if lower % 2 == 0 else lower + 1
	var max = upper if upper % 2 == 0 else upper - 1
	return randi() % ((max - min) / 2 + 1) * 2 + min

func generate_odd(lower:int, upper:int) -> int:
	'''
	Generate an even number between two given numbers.
	'''
	# Make sure min and max are odd
	if lower % 2 == 0:
		lower += 1
	if upper % 2 == 0:
		upper -= 1
	var count = ((upper - lower) / 2) + 1
	return lower + 2 * randi() % count

#------------------------------------------------------------------------------#
#---------------------------------------------#
#                 HELPERS                     #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# Sets the maze dimensions and diameter
func _set_nd(n:int,d:int):
	cur_maze[C.AM_N] = n
	cur_maze[C.AM_D] = d


# Set the neighbours of all elements in the graph
# Depending on whether the neighbours are solid or not.
# we again build this recursively because of indeterminate maze dimensions.
func set_all_neighbours():
	_init_traversal()
	_set_all_neighbours(cur_maze[C.AM_N])


# Here, we set all the edges of each node if the neighbour is not solid.
# Therefore, from not solid nodes, we can traverse through and to non solid nodes,
# And for solid nodes, we know if they are adjacant to non-solid nodes
# which is useful for adding edges.
func _set_all_neighbours(n, trav_ind=0):
	# Initialize this hyperplane's positions.
	_set_traversal_zeros(trav_ind)
	
	# Base case: If we have reduced to 1st dimension, determine neigbours
	if n == 1:
		for i in range(cur_maze[C.AM_D]):
			# Get the dictionary for this position.
			var cur = get_cell_node(traversal_pos)
			cur[C.MC_NEIGHBOURS] = _sift_not_solid(_get_valid_neighbours(traversal_pos))
			#print("At " + str(traversal_pos) + ": " + str(cur))
			traversal_pos[trav_ind] += 1
			
	# Otherwise, continue reducing to the 1st dimension
	else: 
		for i in range(cur_maze[C.AM_D]):
			# for each hyperplace, build the n-1 dims.
			# also, pass the hyperplane's traversal pos
			_set_all_neighbours(n-1, trav_ind+1)
			# increment the position in this direction of the hyperplane
			traversal_pos[trav_ind] += 1

# Get all possible neighbour indices for the given indices
func _get_valid_neighbours(indices):
	var neighbours = []
	for i in range(cur_maze[C.AM_N]):
		var neg = indices.duplicate(true)
		var pos = indices.duplicate(true)
		# Get neighbours by moving negatively and positively adjacant
		neg[i] -= 1
		pos[i] += 1
		# check if they are within bounds, add them to neighbours
		if (neg[i] >= 0) and (neg[i] < cur_maze[C.AM_D]):
			neighbours.append(neg)
		if (pos[i] >= 0) and (pos[i] < cur_maze[C.AM_D]):
			neighbours.append(pos)
	return neighbours


# Given a list of indices, return the indices of the items that are not solid
func _sift_not_solid(indices_list):
		# Otherwise, we need to do the check.
		var unsolid = []
		
		# check each neighbour, if not solid then append it.
		for indices in indices_list:
			if not C.IS_SOLID[get_cell_node(indices)[C.MC_OBS]]:
				unsolid.append(indices)
		
		# Return a list of indices for available neighbours
		return unsolid


# Gets the item at the given index
# This method is necessary, because the dimension of
# the array is dependent on the input.
func get_cell_node(indices:Array):
	var cell = cur_maze[C.AM_CELLS]
	for cur_index in indices:
		cell = cell[cur_index]
	return cell


# Generate a cell node as a dictionary of cell properties.
func _init_cell_dict(obs_type):
	return {
		C.MC_OBS:obs_type, # Obstacle type of this cell
		C.MC_NEIGHBOURS:[] # Cell has no known neighbours yet
		}


# initialize the traversal_pos array for the given maze dimensions.
func _init_traversal():
	traversal_pos = []
	for i in cur_maze[C.AM_N]:
		traversal_pos.append(0)


# set the traversal_pos to the initial pos for the currently traversed hyperplane depth
func _set_traversal_zeros(cur_traversal):
	var cur = cur_traversal
	while cur < cur_maze[C.AM_N]:
		traversal_pos[cur] = 0
		cur += 1



	
	
