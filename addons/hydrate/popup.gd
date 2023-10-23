@tool
extends AcceptDialog

signal on_popup_setting_change(is_disabled)


func _on_disable_cb_toggled(button_pressed):
	on_popup_setting_change.emit(button_pressed)
