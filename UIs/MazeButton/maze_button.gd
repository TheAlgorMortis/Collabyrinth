extends Control

'''
A buttom themed around maze obstacle.
'''

signal clicked(name:String)

const FILLER:PackedScene = preload("res://Obstacles/Wall/obst_wall.tscn")

var bt_ele:Array
var block_size:Vector2
var btn_name:String

func _ready():
	#gen_button(1,4,"bit")
	#scale *=3
	pass


func gen_button(rows:int, cols:int, caption:String=""):
	# Forming the size of the button.
	block_size = Vector2(cols, rows) * C.CELL_AREA
	custom_minimum_size = block_size

	$WallControl.columns = cols

	$Button.text = caption
	btn_name = caption
	var right = cols-1
	var bottom = rows-1

	for row in range(rows):
		for col in range(cols):
			var ele = FILLER.instantiate()
			var cur_control = Control.new()
			cur_control.custom_minimum_size = Vector2(36, 36)
			
			cur_control.add_child(ele)
			$WallControl.add_child(cur_control)

			if col == 0:
				ele.add_border(C.DIR_LEFT)
			if col == right:
				ele.add_border(C.DIR_RIGHT)
			if row == 0:
				ele.add_border(C.DIR_UP)
			if row == bottom:
				ele.add_border(C.DIR_DOWN)
				
			bt_ele.append(ele)


func _on_mouse_entered():
	for ele in bt_ele:
		ele.hover()


func _on_mouse_exited():
	for ele in bt_ele:
		ele.leave()


func _on_button_pressed():
	clicked.emit(btn_name)


func _on_button_mouse_entered():
	for ele in bt_ele:
		ele.hover()


func _on_button_mouse_exited():
	for ele in bt_ele:
		ele.leave()


func set_showing(is_enabled:bool=true):
	$Button.disabled = !is_enabled
	visible = is_enabled
