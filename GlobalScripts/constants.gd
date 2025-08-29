extends Node


#---------------------------------------------#
#                 Maze elements               #
#---------------------------------------------#

# Obstacles (Static objects that don't move around. Some act as obstacles)
# Only act with the player when the player interacts with it
const OBS_WALL = "W"
const OBS_AIR = "A"
const OBS_START = "S"
const OBS_END = "E"

# Used only in maze gen.
const OBS_NONE = "N"

# Entities (Dynamic objects that can move around the maze and react to players)
# Has unique behaviour
const ENT_PLAYER = "P"

# Whether certain element types are solid (passable)
const IS_SOLID = {
	OBS_WALL:true,
	OBS_AIR:false,
	OBS_START:false,
	OBS_END: false,
	OBS_NONE: false
}

# Enums for maze dictionaries
# MC stands for Maze Cell
enum {MC_OBS, MC_NEIGHBOURS}

enum {V_BOOL, V_PARENT}


# Indices in text cells (split by :)
enum {TI_OBS, TI_ENT}
const TI_LENGTH = 2

# Elements that HAVE to be in EVERY MAZE, and also MUST BE UNIQUE
const REQUIRED_AS_UNIQUE = [OBS_START, OBS_END, ENT_PLAYER]

#Constants for maze elements
const ELEMENT_SCENES = {
		OBS_WALL: preload("res://Obstacles/Wall/obst_wall.tscn"),
		OBS_AIR: preload("res://Obstacles/obs_air.tscn"),
		OBS_START: preload("res://Obstacles/Entrance/entrance.tscn"),
		OBS_END: preload("res://Obstacles/Exits/exit.tscn")	
	}


#---------------------------------------------#
#              Abstract Maze                  #
#---------------------------------------------#

enum {AM_N, AM_D, AM_CELLS, AM_REQ_UNQ_POS}


#---------------------------------------------#
#                Directions                   #
#---------------------------------------------#


# Directions as vectors
const DIR_UP = Vector2(0,-1)
const DIR_DOWN = Vector2(0,1)
const DIR_LEFT = Vector2(-1,0)
const DIR_RIGHT = Vector2(1,0)

# Directions as strings
const STR_UP = "Up"
const STR_DOWN = "Down"
const STR_LEFT = "Left"
const STR_RIGHT = "Right"

const DIRECTIONS:Dictionary = {
		STR_UP    : DIR_UP,
		STR_DOWN  : DIR_DOWN,
		STR_LEFT  : DIR_LEFT,
		STR_RIGHT : DIR_RIGHT
	}
	
const DIRECTIONS_2:Dictionary = {
		STR_UP    : DIR_UP * 2,
		STR_DOWN  : DIR_DOWN * 2,
		STR_LEFT  : DIR_LEFT * 2,
		STR_RIGHT : DIR_RIGHT* 2
	}

# Axes of movement
const AXIS_X = 0
const AXIS_Y = 1
const X_DIRS = [DIR_RIGHT, DIR_LEFT]
const Y_DIRS = [DIR_DOWN, DIR_UP]
const AXES_STRINGS = ['X','Y']
const AXES_DICT = {
		AXIS_X:X_DIRS,
		AXIS_Y:Y_DIRS
	}

const AXES_MAG_INDEX = 0

# Constants for border angles
const ANGLES:Dictionary = {DIR_UP:0, DIR_DOWN:PI, DIR_LEFT:-PI/2, DIR_RIGHT:PI/2}

# Constants for sizing and movement
const CELL_AREA:int = 40
const MOVE_DIST:int = CELL_AREA
const NUDGE_DIST:int = 2

# The null vector
const NULL_VECTOR:Vector2 = Vector2(0,0)




#---------------------------------------------#
#                Array Maths                  #
#---------------------------------------------#


func arr_equal(arr1, arr2):
	if arr1.size() != arr2.size():
		return false
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	return true

func arr_negate(arr):
	var negated = arr.duplicate()
	for i in range(arr.size()):
		negated[i] *= -1
	return negated


func arr_add(a1, a2):
	var result = []
	for i in range(a1.size()):
		result.append(a1[i] + a2[i])
	return result


func arr_select_random_element(a):
	var i = randi() % a.size()
	return a[i]




#---------------------------------------------#
#                 Debugging                   #
#---------------------------------------------#




func dp(message:String, effective:bool):
	'''
	Print a message if the boolean is true.
	'''
	if effective:
		print(message)


func dp_title(message:String, effective:bool):
	'''
	Print a title message if the boolean is true.
	'''
	if effective:
		print("-------------------------------------------")
		print(message)
		print("-------------------------------------------")
	
