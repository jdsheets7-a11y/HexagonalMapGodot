extends Node3D
class_name Unit

var data : UnitData

var current_health: int
var movement_remaining: int
var attacks_remaining: int
var troops_remaining: int

@export var has_moved: bool = false
@export var has_attacked: bool = false
@export var team = TeamStatus.TEAM_1

var occupied_tile : Tile
var unit_id: int = -1

enum TeamStatus {TEAM_1, TEAM_2}


func _ready() -> void:
	initialize()
	
	add_to_group("units")
	
	var mesh = $CSGCylinder3D
	mesh.material = mesh.material.duplicate()
	
	$Healthbar/Sprite3D.texture = $Healthbar/SubViewport.get_texture()
	$NameTag.text = data.unit_name + " " + str(team)
	update_health()


func initialize():
	current_health = data.max_health
	attacks_remaining = data.attacks
	movement_remaining = data.movement_range


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
	$Healthbar/SubViewport/Control/ProgressBar.max_value = data.max_health
	$Healthbar/HealthNumber.text = "%d / %d" % [current_health, data.max_health]
	if current_health <= 0:
		queue_free()
