extends "res://Obstacles/abstract_obstacle.gd"

'''
Class for walls, the simplest obstacle types in mazes.
'''


# Called when the node enters the scene tree for the first time.
func _ready():
	set_border_type(preload("res://Obstacles/Wall/bord_wall.tscn"))
	$fill_animation.play("Default")


# Used for buttons
func hover():
	$fill_animation.play("Hover")


# Used for buttons
func leave():
	$fill_animation.play("Default")
