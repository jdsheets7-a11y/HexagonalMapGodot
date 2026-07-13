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

enum TeamStatus {
	PLAYER, 
	ENEMY,
	}
	
@export var team = TeamStatus.PLAYER


func _ready() -> void:
	current_health = max_health
	add_to_group("units")
	var mesh = $CSGCylinder3D
	mesh.material = mesh.material.duplicate()


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

## Changing color depending on team
func update_team_color():
	var mesh = $CSGCylinder3D
	if team == TeamStatus.ENEMY:
		mesh.material.albedo_color = Color.RED
	elif team == TeamStatus.PLAYER:
		mesh.material.albedo_color = Color.BLUE
