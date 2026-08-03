extends Control

@onready var grid = $UnitPanel/VBoxContainer/ScrollContainer/GridContainer
var unit_container = preload("res://scenes/unit_container.tscn")

var data : UnitData
var selected_units: Array[UnitData] = []


func _on_back_button_pressed() -> void:
	$ArmyPickerPanel.visible = true


func _on_humans_pressed() -> void:
	load_units(UnitData.Faction.HUMAN)
	$ArmyPickerPanel.visible = false


func _on_robots_pressed() -> void:
	load_units(UnitData.Faction.ROBOT)
	$ArmyPickerPanel.visible = false


func load_units(faction: UnitData.Faction):
	for child in grid.get_children():
		child.queue_free()
	
	print("Loading faction: ", faction)
	print("Units in database: ", UnitDatabase.unit_catalog.values())
	
	for unit in UnitDatabase.unit_catalog.values():
		if unit.faction != faction:
			continue
		
		var unit_ui = unit_container.instantiate()
		grid.add_child(unit_ui)
		
		unit_ui.data = unit
		unit_ui.unit_selected.connect(_on_unit_selected)
		
		#populate UI with correct data
		unit_ui.unit_nametag.text = unit.unit_name
		unit_ui.points.text = str(unit.point_cost)
		unit_ui.icon.texture = unit.icon


func _on_unit_selected(unit: UnitData):
	$YourArmyPanel/MarginContainer/VBoxContainer/ItemList.add_item(unit.unit_name)
	
	selected_units.append(unit)
	print(selected_units)


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

#Add save functionality
func _on_save_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
