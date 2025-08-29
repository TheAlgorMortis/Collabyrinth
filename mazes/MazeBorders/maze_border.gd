extends Node2D

'''
The Maze Border scene is used to generate dynamic maze borders given the matrix dimensions of a maze window
'''

#---------------------------------------------#
#          Constants and Variables            #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#


# Border Segment scene
const SEGMENT:PackedScene = preload("res://mazes/MazeBorders/border_segment.tscn")


# Array holding the segments
var border_elements:Array=[]


#---------------------------------------------#
#                 Functions                   #
#---------------------------------------------#
#--------------------------------------------------------------------------------------------------#

func _ready():
	generate_border(2,2)
	pass


# Generate a border given the row and col count of the border
func generate_border(rows:int, cols:int):
	var final_row = (rows-1) * C.CELL_AREA
	var final_col = (cols-1) * C.CELL_AREA
	
	for ele in border_elements:
		ele.queue_free()
	border_elements = []
	
	var top_pos = 0
	for i in range(rows):
		var left = SEGMENT.instantiate()
		var right = SEGMENT.instantiate()
		left.position.x = 0
		right.position.x = final_col
		left.position.y = top_pos
		right.position.y = top_pos
		left.rotate_segment(-PI/2)
		right.rotate_segment(PI/2)
		top_pos += C.CELL_AREA
		add_child(left)
		add_child(right)
		border_elements.append(left)
		border_elements.append(right)
		

	var left_pos = 0
	for i in range(cols):
		var top = SEGMENT.instantiate()
		var bottom = SEGMENT.instantiate()
		top.position.y = 0
		bottom.position.y = final_row
		top.position.x = left_pos
		bottom.position.x = left_pos
		bottom.rotate_segment(PI)
		left_pos += C.CELL_AREA
		add_child(top)
		add_child(bottom)
		border_elements.append(top)
		border_elements.append(bottom)
