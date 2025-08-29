extends Control

signal done

func _ready():
	$OuterPanels/LeftPanels/MultiplayerPanel/multiMargin/mulitVbox/HBoxContainer/LineEdit.text = GlbUser.username
	$OuterPanels/LeftPanels/ScreenPanel/screenMargin/screenVbox/HBoxContainer/MenuBar.select(GlbUser.screen_type)

func _on_done_pressed():
	GlbUser.set_username($OuterPanels/LeftPanels/MultiplayerPanel/multiMargin/mulitVbox/HBoxContainer/LineEdit.text)
	done.emit()

func _on_menu_bar_item_selected(index):
	GlbUser.set_screen(index)
	GlbUser.change_screen(index)
