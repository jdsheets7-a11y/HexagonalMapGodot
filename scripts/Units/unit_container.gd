extends Control

var data : UnitData

signal unit_selected(data)

@onready var icon = $Panel/VBoxContainer/Icon
@onready var unit_nametag = $Panel/VBoxContainer/HBoxContainer/UnitName
@onready var points = $Panel/VBoxContainer/HBoxContainer/Points



func _on_button_pressed():
	unit_selected.emit(data)
