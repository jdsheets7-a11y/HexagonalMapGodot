extends Node3D
class_name Unit

@export var unit_name : String
@export var max_health: int
@export var current_health: int
@export var movement_range: int 
@export var damage: int
@export var attack_range: int
@export var attacks: int
@export var attacks_remaining: int
@export var armor: int
@export var armor_pen: int
@export var movement_remaining: int = movement_range
@export var point_cost: int

@export var model: PackedScene

@export var has_moved: bool = false
@export var has_attacked: bool = false
var occupied_tile : Tile

@export var team = TeamStatus.TEAM_1

enum TeamStatus {TEAM_1, TEAM_2}

var unit_id: int = -1

func _ready() -> void:
	current_health = max_health
	attacks_remaining = attacks
	movement_remaining = movement_range
	
	add_to_group("units")
	
	var mesh = $CSGCylinder3D
	mesh.material = mesh.material.duplicate()
	$Healthbar/Sprite3D.texture = $Healthbar/SubViewport.get_texture()
	$NameTag.text = unit_name + str(team)
	update_health()



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
	if team == TeamStatus.TEAM_2:
		mesh.material.albedo_color = Color.RED
	elif team == TeamStatus.TEAM_1:
		mesh.material.albedo_color = Color.BLUE

## Update healthbar
func update_health():
	$Healthbar/SubViewport/Control/ProgressBar.value = current_health
	$Healthbar/SubViewport/Control/ProgressBar.max_value = max_health
	$Healthbar/HealthNumber.text = "%d / %d" % [current_health, max_health]
	
