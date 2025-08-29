extends Control

'''
Backdrop elements for mazes.
'''

var pos_percentages:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	rotation = randf_range(0, 2*PI)
	# Randomize anchors between 0 and 1 (relative poon():sition)
	$Animated.animation = "default"
	$Animated.frame = randi() % $Animated.sprite_frames.get_frame_count("default")
	$Animated.play()


func set_random_anchor():
	anchor_left = randf()
	anchor_top = randf()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
