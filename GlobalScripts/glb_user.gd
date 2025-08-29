extends Node

const settings_file = "res://GlobalScripts/settings.txt"

var username = "TheNavigator"
var screen_type = 1


# Game information
var axis = 0
var maze_rad = 1
var game_rad = 1

func _ready():
	read_particulars()
	change_screen()


func set_username(_username):
	username = _username
	write_particulars()


func change_screen(index=screen_type):
	if index == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_screen(index):
	screen_type = index
	write_particulars()


# Read the settings from the settings text file.
func read_particulars():
	var settings = FileAccess.open(settings_file, FileAccess.READ)
	if not settings:
		emit_signal("invalid_maze_file","Failed to open file")
	username = settings.get_line().strip_edges()
	screen_type = int(settings.get_line().strip_edges())
	settings.close()


# Write settings to the settings text file.
func write_particulars():
	var settings = FileAccess.open(settings_file, FileAccess.WRITE)
	if not settings:
		emit_signal("invalid_maze_file","Failed to open file")
	settings.store_line(username)
	settings.store_line(str(screen_type))
	settings.close()


# Update game information
func update_game_information(new_maze_rad, new_game_rad, new_axis):
	maze_rad = new_maze_rad
	game_rad = new_game_rad
	axis = new_axis
	
