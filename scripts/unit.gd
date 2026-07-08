extends Node3D
class_name Unit

@export var unit_name : String = "Unit"
@export var max_health: int = 10
var current_health: int = 10
@export var movement_range: int = 3
@export var movement_remaining: int = movement_range
@export var model: PackedScene
@export var has_moved: bool = false

var occupied_tile : Tile
var team # which "team" does this unit belong to


func _ready() -> void:
	current_health = max_health
	add_to_group("units")

func turn_start():
	for unit in get_tree().get_nodes_in_group("units"):
		unit.movement_remaining = unit.movement_range
		unit.has_moved = false


## Put this unit on a tile at position
func place_unit(new_position : Vector3, tile):
	position = new_position
	leave_tile()
	occupy_tile(tile)


func occupy_tile(tile : Tile):
	occupied_tile = tile
	tile.occupier = self


func leave_tile():
	if occupied_tile:
		occupied_tile.occupier = null
