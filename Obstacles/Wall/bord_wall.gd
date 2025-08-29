extends AnimatedSprite2D

'''
Class for borders for walls. 
Borders are placed on all walls that are exposed to non-obstacle maze elements.
'''

# Called when the node enters the scene tree for the first time.
func _ready():
	play("default")


# Play the bump animation
func bump():
	play("Bump")

# Return to default when the bump animation is complete
func _on_animation_finished():
	play("default")
