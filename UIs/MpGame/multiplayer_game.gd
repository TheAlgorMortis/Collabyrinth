extends Control

@onready var maze = $UiController/Collabyrinth
@onready var ui_controller = $UiController
@onready var settings = $UiController/Settings
@onready var controllers = $UiController/Controllers
# Settings panels
@onready var host_settings = $UiController/Settings/HostSettings
@onready var client_settings = $UiController/Settings/ClientSettings
# Ui buttons
@onready var b_start = $UiController/Controllers/Start
@onready var b_back = $UiController/Controllers/Back
@onready var b_disconnect = $UiController/Controllers/Disconnect
@onready var b_abort = $UiController/Controllers/Abort
@onready var message = $UiController/Controllers/Panel/Message
var settings_visible = false;



# Called when the node enters the scene tree for the first time.
func _ready():
	#maze.load_maze_from_file()
	#maze.produce()
	#maze.set_window(1,5)
	#maze.start_game()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func load_game():
	
	var maze_dict = AM.generate_prims(GlbUser.maze_rad)
	build_and_load.rpc(maze_dict)
	
@rpc("any_peer", "call_local")
func build_and_load(maze_dict):
	prep_panels()
	maze.build_from_dict(maze_dict)
	maze.produce()
	maze.set_axis_collabyrinth(GlbUser.axis, GlbUser.game_rad)
	maze.start_game()
	message.text = "SEARCH FOR THE EXIT"
	b_start.visible = false
	

func prep_panels():
	host_settings.visible = false
	client_settings.visible = false
	if GlbUser.axis == C.AXIS_X:
		ui_controller.columns = 1
		settings.columns = 10
		controllers.columns = 20
	else:
		ui_controller.columns = 3
		settings.columns = 1
		controllers.columns = 1
	b_back.visible = false
	b_disconnect.visible = false
	b_abort.visible = false

func _on_settings_button_pressed():
	if not settings_visible:
		if multiplayer.is_server():
				host_settings.visible = true
		else:
			client_settings.visible = true
		settings_visible = true
	else:
		host_settings.visible = false
		client_settings.visible = false
		settings_visible = false


func _on_collabyrinth_exited():
	message.text = "CONGRATS! READY FOR NEXT MAZE."
	if multiplayer.is_server():
		b_start.visible = true


func _on_start_pressed():
	load_game()
