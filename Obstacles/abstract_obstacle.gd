extends Area2D

'''
An abstract obstacle is designed to handle the different obstacle types and work on them from the most
abstracted level.
It is intended to serve as a parent for all of the obstacle types.
'''


#---------------------------------------------#
#                   Vars                      #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# The border type
var _border_type:PackedScene


# Borders on the obstacles
var borders:Dictionary = {C.DIR_DOWN:0, C.DIR_UP:0, C.DIR_RIGHT:0, C.DIR_LEFT:0}


#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Set the border type of this obstacle (a method used in children classes)
func set_border_type(border_type):
	_border_type = border_type


# Add a border to this obstacle in the direction
func add_border(direction, border_type=_border_type):
	# If border is not yet set
	if borders.get(direction) == 0:
		# Create new border
		var border = border_type.instantiate()
		# Rotate it accordingly
		border.rotate(C.ANGLES.get(direction))
		
		add_child(border)
		borders[direction] = border


# Setup for the bump method of an obstacle.
func bump(move_dir):
	# since the move_dir is going towards the block,
	# and the border is facing towards the opposite direction,
	# We have to invert the move dir
	var direction = -move_dir
	if borders.get(direction) not in [0]:
		borders.get(direction).bump()
