extends Control

'''
Forms backgrounds for mazes
'''

#---------------------------------------------#
#          Constants and Variables            #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

const NUDGE_SHIFTS:Array = [20.0/20.0, 10.0/20.0, 5.0/20.0, 3/20.0, 2/20.0]

var elements:Array = []
var maze_shifts:bool = true
var back_item:PackedScene = preload("res://Backdrop/back_item.tscn")
var layers:Array
var base_size = Vector2()

#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

func _ready():
	pass


# generates the backdrop (For the UFO theme) for a maze with a given diameter
func generate_for_maze(dia:int=25):
	gen(40 * dia, 40 * dia, dia)


# generate a backdrop given dimes and a default diameter
func generate_from_dims(dim_x:int=get_viewport().size.x, dim_y:int=get_viewport().size.y, dia:int=30):
	gen(dim_x, dim_y,dia)


# Generate
func gen(dim_x,dim_y, dia):
	# Shift used to determine bounds of the rect's anchors
	var shift = (Vector2(dim_x, dim_y) / 7) / Vector2(dim_x, dim_y)

	# Here, we are making the control slightly larger than its parent, so that when we spawn the backitems, 
	# we can just generate a rancom anchor from 0 to 1, and they will still generate off the screen,
	# since the control itself is slightly larger than the screen.	

	anchor_left = -shift.x
	anchor_right = 1 + shift.x
	anchor_top = -shift.y
	anchor_bottom = 1 + shift.y

	# Setting up counts and scales for each parralax layer (WE SHOULD INVESTIGATE NATIVE PARRALAX NODES FOR THIS)
	var counts = [[0,3],[3,dia],[2*dia, 4*dia], [6*dia, 12*dia], [20*dia, 30*dia]]
	var scales = [[0.7, 0.8],[0.5,0.7], [0.5, 0.3], [0.3, 0.2], [0.2, 0.1]]
	layers = [$Top, $TopMiddle, $Middle, $BottomMiddle, $Bottom]

	# Freeing any pre-existing backitems as a safeguard for performance and bugs
	for ele in elements:
		ele.queue_free()

	# recreating elements array
	elements = []

	# Looping through the layers
	for i in range(5):
		# Selecting the scale range for this layer
		var this_scale = scales[i]
		# Selecting the number of backitems to appear on this layer
		var this_counts = counts[i]
		var num_elements = int(randf_range(this_counts[0], this_counts[1]))
		# Looping for the number of elements in the layer
		for j in range(num_elements):
			# Instantiate a backitem
			var element = back_item.instantiate()
			# Give the backitem a random scale
			var random_scalar = randf_range(this_scale[0], this_scale[1])
			element.scale *= random_scalar
			# Generating random position
			# Appending the backitems to the elements list
			elements.append(element)
			# Adding the child to the given layer
			layers[i].add_child(element)
			# Setting the backitems anchor positions
			element.set_random_anchor()


# Nudge the elements in the background
func nudge(move_dir:Vector2):
	for i in range(5):
		layers[i].position += move_dir * NUDGE_SHIFTS[i]


# Set the colour of the background. Defaults to black.
func set_color(r:int=0,g:int=0,b:int=0):
	$ColorRect.color = Color8(r,g,b)
