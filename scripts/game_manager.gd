extends Node

enum GameState {
	DEPLOYMENT,
	TURN
}

var game_state = GameState.TURN
var peer_to_team: Dictionary = {}
var local_team = Unit.TeamStatus
var turn_counter = 1
var can_attack: bool = true
var army_list: Array[UnitData] = []
var master_unit_list: Array[Unit] = []
var print_master_list: Array[String] = []

var current_unit_index: int = 0

var next_unit_id: = 0
var units_by_id = {}
var unit_scene = preload("res://scenes/Units/prototype_unit.tscn")

var deployment_rows: Vector2
const DEPLOYMENT_DEPTH := 5

var deploy_status = {
	Unit.TeamStatus.TEAM_1: false,
	Unit.TeamStatus.TEAM_2: false
}

@onready var hud: HUD
@onready var interaction: INTERACTION


func setup_deployment_zone():
	deployment_rows = get_deployment_rows()
	print("Deployment rows: ", deployment_rows)


func get_deployment_rows() -> Vector2:
	var min_row = INF
	var max_row = -INF
	
	for tile in WorldMap.map_as_dict.values():
		var row = tile.pos_data.grid_position.y
		min_row = min(min_row, row)
		max_row = max(max_row, row)
	
	return Vector2(min_row, max_row)


func get_deployment_tiles(team: Unit.TeamStatus) -> Array[Tile]:
	var deployment_tiles: Array[Tile] = []
	
	
	for tile in WorldMap.map_as_dict.values():
		if is_deployment_tile(tile, team):
			deployment_tiles.append(tile)
	
	return deployment_tiles


func is_deployment_tile(tile: Tile, team: Unit.TeamStatus) -> bool:
	var row = tile.pos_data.grid_position.y
	
	if team == Unit.TeamStatus.TEAM_1:
		return row <= deployment_rows.x + DEPLOYMENT_DEPTH - 1
		
	if team == Unit.TeamStatus.TEAM_2:
		return row >= deployment_rows.y - DEPLOYMENT_DEPTH + 1
	
	return false


func deployment_ready():
	set_player_ready.rpc(local_team)


func sort_master_unit_list():
	master_unit_list.sort_custom(
		func(a: Unit, b: Unit):
			return a.data.speed > b.data.speed
	)


@rpc("any_peer", "call_local", "reliable")
func set_player_ready(team: Unit.TeamStatus):
	deploy_status[team] = true
	
	print(str(team) + " is ready")
	
	if deploy_status[Unit.TeamStatus.TEAM_1] \
	and deploy_status[Unit.TeamStatus.TEAM_2]:
		sort_master_unit_list()
		for i in master_unit_list:
			print_master_list.append(i.data.unit_name)
		print(print_master_list)
		
		start_game.rpc()


@rpc("call_local", "reliable")
func start_game():
	current_unit_index = 0
	game_state = GameState.TURN
	hud.deploy_panel.visible = false
	set_current_unit(current_unit_index)


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
func request_deploy_unit(unit_type: UnitData, tile: Tile):
	if tile == null:
		return
	if game_state != GameState.DEPLOYMENT:
		return
	if not is_deployment_tile(tile, local_team):
		print("Tile is outside deployment zone")
		return
	
	deploy_unit.rpc(
		unit_type.resource_path,
		tile.pos_data.grid_position,
		local_team
	)

@rpc("any_peer", "call_local", "reliable")
func deploy_unit(
	unit_path: String,
	grid_position: Vector2,
	team: Unit.TeamStatus
):
	var unit_type: UnitData = load(unit_path)
	var unit: Unit = UnitDatabase.UNIT_SCENE.instantiate()
	unit.data = unit_type
	
	unit.unit_id = generate_unit_id()
	get_tree().current_scene.add_child(unit)
	units_by_id[unit.unit_id] = unit
	master_unit_list.append(unit)
	
	unit.team = team
	unit.update_team_color()
	
	var tile: Tile = WorldMap.map_as_dict[grid_position]
	unit.place_unit(tile.position, tile)
	
	if team == local_team:
		hud.remove_unit()


# Movement logic
func request_move_unit(unit: Unit, tile: Tile, distance: int):
	if unit == null:
		return
	if tile == null:
		return
	if unit.team != local_team:
		print("Cannot move enemy units")
		return
	if unit != master_unit_list[current_unit_index]:
		print("It is not this unit's turn")
		return
	if tile.occupier != null:
		print("Tile occupied")
		return
	if distance > unit.movement_remaining:
		print("insufficient movement remaining")
		return
	
	move_unit.rpc(
		unit.unit_id,
		tile.pos_data.grid_position,
		distance
	)


@rpc("any_peer", "call_local", "reliable")
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
	if attacker != master_unit_list[current_unit_index]:
		print("It is not this unit's turn")
		return
	if attacker.team == target.team:
		print("Cannot attack friendly units")
		return
	if can_attack == false:
		print("Please wait")
		return
	
	var accuracy = attacker.data.accuracy
	var damage = attacker.data.damage
	var pen = attacker.data.armor_pen
	var armor = target.data.armor
	var attack_results = []
	
	# Setup any attacking related Keywords
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
			"damage": damage
		})
	
	attack_unit.rpc(
		attacker.unit_id,
		target.unit_id,
		attack_results
	)
	
	return true


@rpc("any_peer", "call_local", "reliable")
func attack_unit(
	attacker_id: int,
	target_id: int,
	attack_results
):
	var attacker = get_unit_by_id(attacker_id)
	var target = get_unit_by_id(target_id)
	
	if attacker == null or target == null:
		return
		
		print(attacker.data.unit_name, " attacks ", target.data.unit_name)
	
	can_attack = false
	
	for result in attack_results:
		if target == null:
			return
		
		hud.hit_display(
			result.hit,
			result.wound
		)
		
		if result.hit:
			if result.wound:
				print("Attack hit!")
				target.health_remaining -= result.damage
				target.update_health()
			else:
				print("Attack blocked")
		else:
			print("Attack missed")
		
		await get_tree().create_timer(1.1).timeout
	
	attacker.attacks_remaining -= attacker.data.attacks

	
	await get_tree().create_timer(1.5).timeout
	can_attack = true


func get_unit_by_id(unit_id: int) -> Unit:
	if units_by_id.has(unit_id):
		return units_by_id[unit_id]
	
	print("Unit ID not found:", unit_id)
	return null


func end_turn():
	var current_unit = master_unit_list[current_unit_index]
	if current_unit.team != local_team:
		return
		
	var next_index = current_unit_index + 1
	if next_index >= master_unit_list.size():
		next_index = 0
	interaction.deselect()
	set_current_unit.rpc(next_index)


@rpc("any_peer", "call_local", "reliable")
func set_current_unit(index: int):
	current_unit_index = index
	
	var unit = master_unit_list[current_unit_index]
	
	unit.movement_remaining = unit.data.movement_range
	unit.has_moved = false
	unit.attacks_remaining = unit.data.attacks
	
	if unit.team == local_team:
		interaction.select_unit(unit)

@rpc("call_local", "reliable")
func start_deployment():
	if multiplayer.is_server():
		local_team = Unit.TeamStatus.TEAM_1
		print("Assigned Team 1, local_team = ", local_team)
	else:
		local_team = Unit.TeamStatus.TEAM_2
		print("Assigned Team 2, local_team = ", local_team)
	
	print("START GAME local_team: ", local_team)
	
	game_state = GameState.DEPLOYMENT
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
