extends Node

enum GameState {
	DEPLOYMENT,
	TEAM_1_TURN,
	TEAM_2_TURN
}

var peer_to_team: Dictionary = {}
var game_state = GameState.TEAM_1_TURN
var current_team = Unit.TeamStatus.TEAM_1
var local_team = Unit.TeamStatus
var turn_counter = 1
var can_attack: bool = true

var next_unit_id: = 0
var units_by_id = {}
var unit_scene = preload("res://scenes/Units/prototype_unit.tscn")

@onready var hud: HUD
@onready var interaction: INTERACTION

func generate_unit_id() -> int:
	var id = next_unit_id
	next_unit_id += 1
	return id


# Synchorinzed world generation via seed
@rpc("authority", "call_remote", "reliable")
@warning_ignore("shadowed_global_identifier")
func send_world_seed(seed: int):
	var world_gen = get_tree().current_scene.get_node(
		"Builder/WorldGenerator"
	)
	
	world_gen.start_generation(seed)


# Deployment logic
func request_deploy_unit(unit_type: String, tile: Tile):
	print("Request deploy called. Local team: ", local_team)
	if tile == null:
		return
		
	if multiplayer.is_server():
		request_deploy_unit_rpc(
			unit_type,
			tile.pos_data.grid_position,
		)
	else:
		request_deploy_unit_rpc.rpc_id(
			1,
			unit_type,
			tile.pos_data.grid_position,
		)


@rpc("any_peer", "reliable")
func request_deploy_unit_rpc(
	unit_type: String,
	grid_position: Vector2
):
	print("Server received deploy request")
	
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	if sender_id == 0:
		sender_id = 1
	
	var team = peer_to_team.get(sender_id)
	
	if team == null:
		print("Unknown player")
		return
	
	var tile: Tile = WorldMap.map_as_dict[grid_position]
	
	if tile == null:
		return
	
	if tile.occupier != null:
		print("Tile is occupied")
		return
	
	spawn_unit.rpc(
		unit_type,
		grid_position,
		team
	)

@rpc("authority", "call_local", "reliable")
func spawn_unit(unit_type: String, grid_position: Vector2, team: Unit.TeamStatus):
	@warning_ignore("static_called_on_instance")
	var unit_to_spawn = UnitDatabase.get_unit(unit_type)
	
	if unit_to_spawn == null:
		print("Invalid unit type")
		return
	
	var unit: Unit = UnitDatabase.UNIT_SCENE.instantiate()
	unit.data = unit_to_spawn
	
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
	if current_team != local_team:
		print("It is not your turn")
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
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	
	var sender_team = peer_to_team.get(sender_id)
	
	if sender_team == null:
		print("Unknown player")
		return
	
	if unit.team != sender_team:
		print("Cannot move with enemy units")
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
func request_attack(attacker: Unit, target: Unit):
	if attacker == null:
		return
	if target == null:
		return
	if attacker.team != local_team:
		print("Cannot attack with enemy units")
		return
	if attacker.attacks_remaining <= 0:
		print("Unit is out of attacks")
		return
	if current_team != local_team:
		print("It is not your turn")
		return
	if attacker.team == target.team:
		print("Cannot attack friendly units")
		return
	if can_attack == false:
		print("Please wait")
		return
	
	if multiplayer.is_server():
		server_request_attack(attacker.unit_id, target.unit_id)
	else:
		server_request_attack.rpc_id(1, attacker.unit_id, target.unit_id)
	
	return true


@rpc("any_peer", "reliable")
func server_request_attack(attacker_id: int, target_id: int):
	if not multiplayer.is_server():
		return
	
	var attacker = get_unit_by_id(attacker_id)
	var target = get_unit_by_id(target_id)
	
	if attacker == null or target == null:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	var sender_team = peer_to_team.get(sender_id)
	
	if sender_team == null:
		print("Unknown player")
		return
	
	if attacker.team != sender_team:
		print("Cannot attack with enemy units")
		return
	
	var accuracy = attacker.data.accuracy
	var damage = attacker.data.damage
	var pen = attacker.data.armor_pen
	var armor = target.data.armor
	var attack_results = []
	
	#Setup any attacking related Keywords
	if attacker.data.INFANTRY:
		attacker.attacks_remaining = attacker.troops_remaining * attacker.data.attacks
	if attacker.data.CONTROL:
		attacker.attacks_remaining = target.troops_remaining
	
	for i in range(attacker.attacks_remaining):
		var hit: bool = accuracy >= randi_range(1, 100)
		var wound = false
		
		if hit:
			wound = clamp(armor - pen, 0, armor) <= randi_range(1, 10)
		
		attack_results.append({
			"hit": hit,
			"wound": wound,
			"damage": damage})
	
	
	attack_unit.rpc(
		attacker_id,
		target_id,
		attack_results)


@rpc("authority", "call_local", "reliable")
func attack_unit(
	attacker_id: int,
	target_id: int,
	attack_results):
	
	print("attack_unit called on peer ", multiplayer.get_unique_id())
	
	var attacker = get_unit_by_id(attacker_id)
	var target = get_unit_by_id(target_id)
	
	if attacker == null or target == null:
		return
	
	can_attack = false
	
	for result in attack_results:
		
		hud.hit_display(
			result.hit,
			result.wound)
		
		if result.hit:
			if result.wound:
				print("Attack hit!")
				target.current_health -= result.damage
				target.update_health()
			else:
				print("Attack blocked")
		else:
			print("Attack missed")
		
		await get_tree().create_timer(1.1).timeout
	
	
	attacker.attacks_remaining -= attacker.data.attacks
	print(attacker.data.unit_name, " attacks ", target.data.unit_name)
	
	await get_tree().create_timer(1.5).timeout
	can_attack = true


func get_unit_by_id(unit_id: int) -> Unit:
	if units_by_id.has(unit_id):
		return units_by_id[unit_id]
	
	print("Unit ID not found:", unit_id)
	return null


#End turn logic
func end_turn():
	if current_team != local_team:
		return
	
	if multiplayer.is_server():
		if game_state == GameState.TEAM_1_TURN:
			set_turn.rpc(
				GameState.TEAM_2_TURN,
				Unit.TeamStatus.TEAM_2,
				turn_counter
			)
		else:
			set_turn.rpc(
				GameState.TEAM_1_TURN,
				Unit.TeamStatus.TEAM_1,
				turn_counter + 1
			)
	else:
		request_end_turn_rpc.rpc_id(1)

@rpc("any_peer", "reliable")
func request_end_turn_rpc():
	if !multiplayer.is_server():
		return
	
	if game_state == GameState.TEAM_1_TURN:
		set_turn.rpc(
			GameState.TEAM_2_TURN,
			Unit.TeamStatus.TEAM_2,
			turn_counter
		)
	else:
		set_turn.rpc(
			GameState.TEAM_1_TURN,
			Unit.TeamStatus.TEAM_1,
			turn_counter + 1
		)


@rpc("authority", "call_local", "reliable")
func set_turn(
	new_state: GameState,
	new_team: Unit.TeamStatus,
	new_turn: int
):
	game_state = new_state
	current_team = new_team
	turn_counter = new_turn
	
	for unit in get_tree().get_nodes_in_group("units"):
		unit.movement_remaining = unit.data.movement_range
		unit.has_moved = false
		unit.attacks_remaining = unit.data.attacks


@rpc("call_local", "reliable")
func start_game():
	if multiplayer.is_server():
		local_team = Unit.TeamStatus.TEAM_1
		print("Assigned Team 1")
	else:
		local_team = Unit.TeamStatus.TEAM_2
		print("Assigned Team 2")
	
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")


@rpc("any_peer", "reliable")
func request_game_state(new_state: int):
	if not multiplayer.is_server():
		return
	
	set_game_state.rpc(new_state)

@rpc("authority", "call_local", "reliable")
func set_game_state(new_state: int):
	@warning_ignore("int_as_enum_without_cast")
	game_state = new_state
