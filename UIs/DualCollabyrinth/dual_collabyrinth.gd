extends Node2D

'''
A Scene made to test the dual nature of the collabyrinth
'''

@onready var x_maze = $HBoxContainer/Panel/TrimmedMaze
@onready var y_maze = $HBoxContainer/Panel2/TrimmedMaze2

# Called when the node enters the scene tree for the first time.
func _ready():
	x_maze.load_maze_from_file()
	x_maze.produce()
	x_maze.set_axis_collabyrinth(C.AXIS_X, 5)
	x_maze.start_game()
	
	y_maze.load_maze_from_file()
	y_maze.produce()
	y_maze.set_axis_collabyrinth(C.AXIS_Y, 5)
	y_maze.start_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
