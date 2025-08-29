extends Area2D

'''
An abstract player is designed to handle the different player types and work on them from the most
abstracted level.
It is intended to serve as a parent for all of the playable characters.
'''

signal nudged
signal asserted

#---------------------------------------------#
#          Constants and Variables            #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

# Default size of the player
const UNIT_SIZE:int = 30
# The number of frames in a movement animation
const JUMP_FRAMES:int = 19
# The number of frames in a bump animation
const BUMP_FRAMES:int = 19
# The unscaled distance that the player moves in total 
const MOVE_DIST:int = 40
# The unscaled distance that the player moves per frame
const NUDGE_DIST:int = 2
# The unscaled movement distance progression per frame of the bump animation
const BUMP_PROGRESSION:Array = [0,1,1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
# Movement directions
const UP:Vector2 = Vector2(0,-1)
const DOWN:Vector2 = Vector2(0,1)
const LEFT:Vector2 = Vector2(-1,0)
const RIGHT:Vector2 = Vector2(1,0)
# Player orientations given movement directions
var ANGLES:Dictionary = {UP: 0, DOWN: PI, LEFT: -PI/2, RIGHT: PI/2}
# The scalar with which to scale down the player and its movements
var _bump_vector_list:Array
# The number of frames that have played in the move animation
var _frame_counter:int = 0
# The number of frames that have played in the bump animation
var _bump_counter:int = 0
# Whether the player is currently in a movement state or not
var is_moving:bool = false
# A directional vector scaled to the scaled distance that the player moves per frame 
var nudge_vector:Vector2
# A positional vector holding the final position of the player after movement
var moved_to:Vector2
# Whether the player will move
var _player_moves:bool = true

#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Called when the node enters the scene tree for the first time.
# Places the player in the idle state.
func _ready():
	do_idle()


func do_idle():
	pass


func reorient(move_dir:Vector2):
	pass


func _get_angle(move_dir):
	return ANGLES.get(move_dir)


#---------------------------------------------#
#                 Movement                    #
#---------------------------------------------#
# These methods are used to control the movement of the player.
# In this class, they cannot be fully used, as they rely on 
# Animation frames from the specific characters.
# These methods just serve as a basis for movement, as the movement 
# patterns for all playable characters will follow this movement structure.
#---------------------------------------------#


# The public move method called by clients
func move(move_dir:Vector2, player_moves:bool=true, exiting=false):
	print("------------------------")
	print("moving player in direction ")
	print(move_dir)
	_player_moves = player_moves
	nudge_vector = move_dir * NUDGE_DIST
	moved_to = position + (move_dir * MOVE_DIST)
	_frame_counter = 0
	is_moving = true
	if exiting:
		do_exit()
	do_move()


func do_exit():
	pass

# Moves the player by a small amount for smooth movement. 
# (IF the player is still meant to be moving in that frame)
func _nudge_player():
	if _player_moves:
		position += nudge_vector
	nudged.emit()


# Asserts that the player's final position is correct after being nudged.
func _assert_new_position():
	if _player_moves:
		position = moved_to
	is_moving = false
	#print("player position asserted")
	asserted.emit()


# Is called after each movement frame to manage
# whether the player must be nudged and handle the 
# is_moving boolean
func move_frame_changed():
	if is_moving:
		_frame_counter += 1
		if _frame_counter > JUMP_FRAMES:
			_assert_new_position()
			#print("Player movement complete")
			#print("------------------------")
		else:
			_nudge_player()


# A method that triggers the animations in the respective player types.
# This must be implemented in all player types to implement player movement.
func do_move():
	pass


#---------------------------------------------#
#                  Bumps                      #
#---------------------------------------------#
# These methods are used to control player bumps.
# In this class, they cannot be fully used, as they rely on 
# Animation frames from the specific characters.
# These methods just serve as a basis for bumps, as the bump
# patterns for all playable characters will follow this bump structure.
#---------------------------------------------#


# The public bump method called by clients
func bump(move_dir:Vector2):
	is_moving = true
	moved_to = position
	_bump_counter = 0
	_generate_bump_list(move_dir)
	do_bump()


# Moves the player by a small amount for smooth movement. 
# (IF the player is still meant to be moving in that frame)
func _nudge_bump():
	position += _bump_vector_list[_bump_counter]
	_bump_counter += 1


# Asserts that the player's final position 
# is the player's position before the bump
func _assert_starting_position():
	position = moved_to
	is_moving = false
	do_idle()
	#print("player position asserted")


# Scales the movement pattern and generates a vector list for the given bump movement.
func _generate_bump_list(move_dir:Vector2):
	#print("generating bump list for this movement...")
	var bumps = []
	bumps.resize(BUMP_FRAMES)
	for frame in range(BUMP_FRAMES):
		bumps[frame] = move_dir * BUMP_PROGRESSION[frame]
	_bump_vector_list = bumps


# A method that triggers the animations in the respective player types.
# This must be implemented in all player types to implement player bumps.
func do_bump():
	pass
