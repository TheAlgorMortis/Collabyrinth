extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


#---------------------------------------------#
#             Button Behaviour                #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# When the exit button is pressed
func _on_title_screen_exit():
	get_tree().quit()


# When the play button is pressed
func _on_title_screen_play():
	pass


#---------------------------------------------#
#                 Settings                    #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# When the settings button is pressed
func _on_title_screen_settings():
	$TitleScreen.set_button_visibility(false)
	$Settings.visible = true


# Returning from the settings menu
func _on_settings_done():
	$Settings.visible = false
	$TitleScreen.set_button_visibility(true)


#---------------------------------------------#
#                Multiplayer                  #
#---------------------------------------------#
#------------------------------------------------------------------------------#


# When the muiltiplay button is pressed
func _on_title_screen_multi():
	$TitleScreen.set_button_visibility(false)
	$MultiMenu.visible = true


# Return to main from multiplayer menu
func _on_multi_menu_return_to_main():
	pass # Replace with function body.
	$MultiMenu.visible = false
	$TitleScreen.set_button_visibility(true)


# When a multiplayer host clicks "start" on the mp menu
func _on_multi_menu_host_starts():
	host_starts_game()


# Host starts game - this runs for all players

func host_starts_game():
	$MultiplayerGame.load_game()
	all_info.rpc()

@rpc("any_peer", "call_local")
func all_info():
	$MultiMenu.visible = false
	$MultiplayerGame.visible = true
	$TitleScreen.set_button_visibility(false)
	$TitleScreen.set_title_visibility(false)
