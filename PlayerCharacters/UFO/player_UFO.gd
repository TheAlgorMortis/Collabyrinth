extends "res://PlayerCharacters/abstract_player.gd"

'''
The UFO-themed playable character, inherited from AbstractPlayer.
'''

#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Play all the idle animations of the components.
func do_idle():
	$Struts.play("Idle")
	$Hull.play("Idle")
	$Rings.play("Idle")
	$Cockpit.play("Default")
	
	
# Play all the idle animations of the components.
func do_exit():
	$Struts.play("Exit")
	$Hull.play("Exit")
	$Cockpit.play("Exit")
	$Rings.play("Idle")


# Reorient the player given the move direction such that
# It is facing the direction of the key that the player presses.
# This is necessary so that animations play in the correct orientations.
func reorient(move_dir:Vector2):
	var angle = _get_angle(move_dir)
	$Rings.rotation = angle
	$Hull.rotation = angle
	$Struts.rotation = angle
	$Forcefield.rotation = angle
	$Cockpit.rotation = angle


#---------------------------------------------#
#                Movement                     #
#---------------------------------------------#


# Start the movement animation, which in turn triggers player movement.
func do_move():
	$Rings.stop()
	$Rings.play("Move")
	


# Nudge the player when the movement animation frame changes
func _on_rings_frame_changed():
	if $Rings.animation == "Move":
		move_frame_changed()


#---------------------------------------------#
#                  Bumps                      #
#---------------------------------------------#


# Start the bump animation, which in turn triggers player bumps
func do_bump():
	#print("UFO bump starting")
	$Rings.play("Idle")
	$Hull.play("Bump")
	$Struts.play("Bump")
	$Forcefield.play("Bump")


# Nudge the player when the bump animation frame changes
func _on_forcefield_frame_changed():
	if $Forcefield.animation == "Bump":
		_nudge_bump()


# Assert the player starting position when the animation ends.
func _on_forcefield_animation_finished():
	if $Forcefield.animation == "Bump":
		_assert_starting_position()
