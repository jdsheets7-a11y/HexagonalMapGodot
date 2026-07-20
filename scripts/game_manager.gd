extends Node

enum GameState {
	DEPLOYMENT,
	TEAM_1_TURN,
	TEAM_2_TURN
}

var game_state = GameState.TEAM_1_TURN
var current_team = Unit.TeamStatus.TEAM_1
var local_team = Unit.TeamStatus
var turn_counter = 0

var next_unit_id: = 0
var units_by_id = {}

func _ready():
	update_turn()

func generate_unit_id() -> int:
	var id = next_unit_id
	next_unit_id += 1
	return id

# Deployment logic
func request_deploy_unit(unit_type: String, tile: Tile):
	if tile == null:
		return
	
	if multiplayer.is_server():
		spawn_unit.rpc(
			unit_type,
			tile.pos_data.grid_position,
			local_team
		)
	else:
		request_deploy_unit_rpc.rpc_id(
			1,
			unit_type,
			tile.pos_data.grid_position
		)

@rpc("any_peer", "reliable")
func request_deploy_unit_rpc(unit_type: String, grid_position: Vector2):
	if not multiplayer.is_server():
		return
	
	var tile: Tile = WorldMap.map_as_dict[grid_position]
	
	if tile == null:
		return
	
	if tile.occupier != null:
		print("Tile is occupied")
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Temporary team assignment until player-team dictionary is added
	var team = Unit.TeamStatus.TEAM_2
	
	spawn_unit.rpc(
		unit_type,
		grid_position,
		team
	)

@rpc("authority", "call_local", "reliable")
func spawn_unit(unit_type: String, grid_position: Vector2, team: Unit.TeamStatus):
	var unit_scene = UnitDatabase.get_unit_scene(unit_type)
	
	if unit_scene == null:
		print("Invalid unit type")
		return
	
	var unit: Unit = unit_scene.instantiate()
	unit.unit_id = generate_unit_id()
	get_tree().current_scene.add_child(unit)
	units_by_id[unit.unit_id] = unit
	
	
	unit.team = team
	unit.update_team_color()
	
	var tile: Tile = WorldMap.map_as_dict[grid_position]
	unit.place_unit(tile.position, tile)



# Movment logic
func request_move_unit(unit: Unit, tile: Tile, distance: int):
	if unit == null:
		return
	if tile == null:
		return
	if unit.team != local_team:
		print("Cannot move enemy units")
		return
	
	if multiplayer.is_server():
		move_unit.rpc(unit.unit_id, tile.pos_data.grid_position, distance)
	else:
		request_move_unit_rpc.rpc_id(
			1,
			unit.unit_id,
			tile.pos_data.grid_position,
			distance
		)

@rpc("any_peer", "reliable")
func request_move_unit_rpc(unit_id: int, grid_position: Vector2, distance: int):
	if not multiplayer.is_server():
		return

	var unit = get_unit_by_id(unit_id)
	if unit == null:
		return

	var tile: Tile = WorldMap.map_as_dict[grid_position]
	if tile == null:
		return

	var sender_team = Unit.TeamStatus.TEAM_1
	if multiplayer.get_remote_sender_id() != 1:
		sender_team = Unit.TeamStatus.TEAM_2

	if unit.team != sender_team:
		print("Cannot move enemy units")
		return

	if tile.occupier != null:
		print("Tile occupied")
		return

	move_unit.rpc(unit_id, grid_position, distance)

@rpc("authority", "call_local", "reliable")
func move_unit(unit_id: int, grid_position: Vector2, distance: int):
	var unit = get_unit_by_id(unit_id)
	if unit == null:
		return
	
	var tile: Tile = WorldMap.map_as_dict[grid_position]
	if tile == null:
		return
	
	unit.place_unit(tile.position, tile)
	unit.movement_remaining -= distance
	unit.has_moved = true
	 
	if unit.team == local_team:
		var interaction = get_tree(). current_scene.get_node("Builder/Interaction_tracker")
		interaction.select_unit(unit)


# Attacking logic
func try_attack(attacker: Unit, target: Unit, p_finder: Pathfinder) -> bool:
	if attacker == null:
		return false
	if target == null:
		return false
	if attacker.attacks_remaining <= 0:
		print("Cannot attack again")
		return false
	if attacker.team == target.team:
		print("Cannot attack friendly units")
		return false
	if attacker.team != local_team:
		print("Cannot attack with enemy unit")
		return false
	
	var attack_tiles = p_finder.find_attackable_tiles(
		attacker.occupied_tile,
		attacker.attack_range
	)
	
	if not attack_tiles.has(target.occupied_tile):
		print("Target out of range")
		return false
	
	target.current_health -= attacker.damage
	target.update_health()
	attacker.attacks_remaining -= 1
	print(attacker.unit_name, " attacks ", target.unit_name)
	print("This unit has ", attacker.attacks_remaining, " attacks left")
	
	return true


func get_unit_by_id(unit_id: int) -> Unit:
	if units_by_id.has(unit_id):
		return units_by_id[unit_id]
	
	print("Unit ID not found:", unit_id)
	return null



func end_turn():
	for unit in get_tree().get_nodes_in_group("units"):
		unit.movement_remaining = unit.movement_range
		unit.has_moved = false
		unit.attacks_remaining = unit.attacks
	if game_state == GameState.TEAM_1_TURN:
		game_state = GameState.TEAM_2_TURN
		current_team = Unit.TeamStatus.TEAM_2
	else:
		game_state = GameState.TEAM_1_TURN
		current_team = Unit.TeamStatus.TEAM_1
		update_turn()


func update_turn():
	turn_counter += 1


@rpc("call_local", "reliable")
func start_game():
	if multiplayer.is_server():
		local_team = Unit.TeamStatus.TEAM_1
		print("Assigned Team 1")
	else:
		local_team = Unit.TeamStatus.TEAM_2
		print("Assigned Team 2")
	
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
