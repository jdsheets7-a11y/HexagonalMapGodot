extends Node


var unit_scenes = {
	"PROTO_UNIT": preload("res://scenes/Units/prototype_unit.tscn"),
	"RANGED_UNIT": preload("res://scenes/Units/ranged_unit.tscn")
	
}


func get_unit_scene(unit_type: String) -> PackedScene:
	if unit_scenes.has(unit_type):
		return unit_scenes[unit_type]
	
	print("Unknown unit type:", unit_type)
	return null
