extends Node

'''
An abstract maze is a class designed to handle maze files and work on them from the most
abstracted level.
- read from and save mazes from files
- Generate random mazes
- Define preset mazes
- Build maze dictionaries for use in tangible maze scenes (basic mazes, trimmed mazes, etc)
- Randomly generate mazes from given presets.

This script is made to treat mazes as abstract classes (more, dictionaries) to build and operate on
'n'-dimensional mazes with diameters of 'd'.
As mazes get more complex, ill add basic functionality to these scripts.
'''

#---------------------------------------------#
#                   Vars                      #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


var traversal_pos = []

# MAZE INFORMATION #
#------------------#

# Maze dimensions
var _n:int
# Maze diameter
var _d:int
# Matrix holding the cell nodes
var _cells:Array
# Dictionary of important maze information
var _req_unq_pos:Dictionary = {}


#---------------------------------------------#
#                 Signal                      #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Used to signal that an invalid maze file has been passed
signal invalid_maze_file


#---------------------------------------------#
#             Maze obtaining                  #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

# Build a maze from an existing maze dict as built by AM
func build_from_dict(maze_dict):
	_n = maze_dict[C.AM_N]
	_d = maze_dict[C.AM_D]
	_cells = maze_dict[C.AM_CELLS]
	_req_unq_pos = maze_dict[C.AM_REQ_UNQ_POS]


# Reading and constructing a maze from a given text file
# This uses AM to read a maze file, then retreives the dict
func build_from_file(file_name:String):
	build_from_dict(AM.build_from_file(file_name))

# build from a randomly generated maze.
func build_from_generation():
	build_from_dict(AM.generate())


#---------------------------------------------#
#                  Getters                    #
#---------------------------------------------#


# Return the location of a unique.
# Returns null if there is no such unique.
func get_unq_pos(unq_name:String):
	return _req_unq_pos[unq_name]


# Return the maze dimension
func get_dims():
	return _n


# Return the maze diameter
func get_dia():
	return _d


# Gets the item at the given index
# This method is necessary, because the dimension of
# the array is dependent on the input.
func get_cell_node(indices:Array):
	var cell = _cells
	for cur_index in indices:
		cell = cell[cur_index]
	return cell


# Return the reference to maze obstacle array
func get_cells():
	return _cells
