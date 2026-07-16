extends Node3D
class_name Unit

@export var unit_name : String = "Warrior"
@export var max_health: int = 10
@export var current_health: int = 10
@export var movement_range: int = 3
@export var damage: int = 1
@export var attack_range: int = 1
@export var attacks: int = 2
@export var attacks_remaining: int = attacks

@export var movement_remaining: int = movement_range
@export var model: PackedScene
@export var has_moved: bool = false
@export var has_attacked: bool = false
var occupied_tile : Tile

@export var team = TeamStatus.PLAYER

enum TeamStatus {PLAYER, ENEMY}



func _ready() -> void:
	current_health = max_health
	add_to_group("units")
	var mesh = $CSGCylinder3D
	mesh.material = mesh.material.duplicate()
	$Healthbar/Sprite3D.texture = $Healthbar/SubViewport.get_texture()
	update_health()
	$Healthbar/SubViewport/Control/ProgressBar.value = 10
	$Healthbar/SubViewport/Control/ProgressBar.max_value = 10
	print($Healthbar/SubViewport/Control/ProgressBar.value)


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

## Update healthbar
func update_health():
	$Healthbar/SubViewport/Control/ProgressBar.value = current_health
	$Healthbar/SubViewport/Control/ProgressBar.max_value = max_health
	$Healthbar/Label3D.text = "%d / %d" % [current_health, max_health]
