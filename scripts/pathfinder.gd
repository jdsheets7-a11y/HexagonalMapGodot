extends Node
class_name PATHFINDER

var neighbor_positions = WorldMap.HEXAGONAL_NEIGHBOR_DIRECTIONS

@export var highlight_marker: PackedScene
@export var attack_marker: PackedScene
@export var deploy_marker: PackedScene
@export var fog: PackedScene
@export var mixed_marker: PackedScene
@export var cover_marker: PackedScene



var data: UnitData

var movement_markers = []
var attack_markers = []
var deploy_markers = []
var mixed_markers = []
var cover_markers = []

var reachable_distances = {}
var attack_distances = {}

const VISION_RANGE: int = 5

enum LOSResult {
	BLOCKED,
	CLEAR,
	PARTIAL_COVER
}

func _ready():
	GameManager.p_finder = self

func find_reachable_tiles(start: Tile, movement_range: int, flying: bool) -> Array[Node3D]:
	reachable_distances.clear()
	var queue = []
	var visited = []
	var reachable_tiles : Array[Node3D]
	var selected_unit = GameManager.interaction.selected_unit
	
	# Start from the initial tile
	queue.append({"tile": start, "distance": 0})
	visited.append(Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y))
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile: Tile = current["tile"]
		var current_distance: int = current["distance"]
		
		if current_distance > movement_range:
			continue
		
		if current_tile.occupier == null:
			if current_tile.terrain == null or not current_tile.terrain.blocks_movement:
				reachable_tiles.append(current_tile)
				reachable_distances[current_tile] = current_distance
		
		var current_pos = current_tile.pos_data.grid_position
		
		if WorldMap.is_map_staggered:
			if current_pos.x % 2 == 0:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_ODD
		
		for direction in neighbor_positions:
			var neighbor_coords = Vector2(current_pos.x + int(direction.x), current_pos.y + int(direction.y))
			if not WorldMap.map_as_dict.has(neighbor_coords) or visited.has(neighbor_coords):
				continue
			
			var neighbor_tile = WorldMap.map_as_dict[neighbor_coords]
			
			if not flying:
				if neighbor_tile.terrain != null and neighbor_tile.terrain.blocks_movement:
					continue
				elif neighbor_tile.occupier != null:
					if not selected_unit.data.NIMBLE and not neighbor_tile.occupier.data.FLYING:
						continue
			
			var movement_cost: int = 1
			if is_adjacent_to_enemy_melee(current_tile, selected_unit.team):
				movement_cost += 1
				
			queue.append({"tile": neighbor_tile, "distance": current_distance + movement_cost})
			visited.append(neighbor_coords)
		
	return reachable_tiles


func find_attackable_tiles(start: Tile, attack_range: int, min_attack_range: int, flying: bool, melee: bool, team: int) -> Array[Node3D]:
	attack_distances.clear()
	var queue = []
	var visited = []
	var attackable_tiles : Array[Node3D]
	
	queue.append({"tile": start, "distance": 0})
	visited.append(Vector2(start.pos_data.grid_position.x, start.pos_data.grid_position.y))
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile : Tile = current["tile"]
		var current_distance : int = current["distance"]
		
		if current_distance > attack_range:
			continue
		
		if current_distance >= min_attack_range:
			var los := get_line_of_sight(start, current_tile, flying)
			
			if los != LOSResult.BLOCKED or (current_tile.occupier != null and current_tile.occupier.data.FLYING):
				if current_tile.terrain == null or not current_tile.terrain.blocks_los:
					if current_tile.occupier == null or current_tile.occupier.team != team:
						attackable_tiles.append(current_tile)
		
		# Measures the attack distance
		attack_distances[current_tile] = current_distance
		
		var current_pos = current_tile.pos_data.grid_position
		
		if WorldMap.is_map_staggered:
			if current_pos.x % 2 == 0:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_EVEN
			else:
				neighbor_positions = WorldMap.NEIGHBOR_DIRECTIONS_ODD
		
		for direction in neighbor_positions:
			var neighbor_coords = Vector2(
				current_pos.x + int(direction.x),
				current_pos.y + int(direction.y)
			)
			
			if not WorldMap.map_as_dict.has(neighbor_coords) or visited.has(neighbor_coords):
				continue
			
			var neighbor_tile = WorldMap.map_as_dict[neighbor_coords]
			
			queue.append({"tile": neighbor_tile, "distance": current_distance + 1})
			visited.append(neighbor_coords)
		
	return attackable_tiles


func highlight_deployment_tiles(selected_nodes: Array[Tile]):
	var marker_diff = selected_nodes.size() - deploy_markers.size()
	
	for i in range(marker_diff):
		var new_marker = deploy_marker.instantiate()
		add_child(new_marker)
		deploy_markers.append(new_marker)
	
	clear_deployment_highlight()
	
	for i in range(selected_nodes.size()):
		var marker = deploy_markers[i]
		var tile: Tile = selected_nodes[i]
		
		marker.position = tile.position
		marker.visible = true


func clear_deployment_highlight():
	for marker in deploy_markers:
		marker.visible = false


func highlight_movement_tiles(selected_nodes: Array[Node3D]):
	var marker_diff = selected_nodes.size() - movement_markers.size()
	
	for m in range(marker_diff):
		var new_marker = highlight_marker.instantiate()
		add_child(new_marker)
		movement_markers.append(new_marker)
	
	clear_movement_highlight()
	
	var start_tile: Tile = GameManager.interaction.selected_unit.occupied_tile
	
	for tile_node in selected_nodes:
		var tile: Tile = tile_node
		if tile == start_tile:
			continue
		
		for marker in movement_markers:
			if not marker.visible:
				marker.position = tile.position
				marker.visible = true
				break


func clear_movement_highlight():
	if movement_markers and movement_markers.size() > 0:
		for m in movement_markers:
			m.visible = false


func highlight_attack_tiles(selected_nodes: Array[Node3D]):
	clear_attack_highlight()
	
	var attack_tiles: Array[Node3D] = []
	var mixed_tiles: Array[Node3D] = []
	var cover_tiles: Array[Node3D] = []
	
	var start_tile: Tile = GameManager.interaction.selected_unit.occupied_tile
	
	for node in selected_nodes:
		var tile: Tile = node
		if tile == start_tile:
			continue
		
		if GameManager.interaction.selected_unit.data.FLYING:
			if reachable_distances.has(tile):
				mixed_tiles.append(tile)
			else:
				attack_tiles.append(tile)
		else:
			if get_line_of_sight(start_tile, tile) == LOSResult.PARTIAL_COVER:
				cover_tiles.append(tile)
			elif reachable_distances.has(tile):
				mixed_tiles.append(tile)
			else:
				attack_tiles.append(tile)
		
		# Flying attacker: check for wall cover on neighboring tiles.
		if GameManager.interaction.selected_unit.data.FLYING:
			var wall_tiles: Array[Tile] = get_wall_tiles_on_line(start_tile, tile)
			
			for wall_tile in wall_tiles:
				for neighbor in wall_tile.neighbors:
					var neighbor_tile: Tile = neighbor
					
					if get_line_of_sight(start_tile, neighbor_tile) == LOSResult.BLOCKED:
						if not cover_tiles.has(neighbor_tile):
							cover_tiles.append(neighbor_tile)
						attack_tiles.erase(neighbor_tile)
						mixed_tiles.erase(neighbor_tile)
	
	# Hide movement markers on mixed tiles
	for tile in mixed_tiles:
		for marker in movement_markers:
			if marker.visible and marker.position == tile.position:
				marker.visible = false
				break
	
	# Hide all markers on cover tiles
	for tile in cover_tiles:
		for marker in movement_markers:
			if marker.visible and marker.position == tile.position:
				marker.visible = false
				break
		for marker in attack_markers:
			if marker.visible and marker.position == tile.position:
				marker.visible = false
				break
		for marker in mixed_markers:
			if marker.visible and marker.position == tile.position:
				marker.visible = false
				break
	
	# Ensure enough attack markers
	var marker_diff = attack_tiles.size() - attack_markers.size()
	for i in range(marker_diff):
		var new_marker = attack_marker.instantiate()
		add_child(new_marker)
		attack_markers.append(new_marker)
	
	# Ensure enough mixed markers
	var mixed_marker_diff = mixed_tiles.size() - mixed_markers.size()
	for i in range(mixed_marker_diff):
		var new_marker = mixed_marker.instantiate()
		add_child(new_marker)
		mixed_markers.append(new_marker)
	
	# Ensure enough cover markers
	var cover_marker_diff = cover_tiles.size() - cover_markers.size()
	for i in range(cover_marker_diff):
		var new_marker = cover_marker.instantiate()
		add_child(new_marker)
		cover_markers.append(new_marker)
	
	for marker in attack_markers:
		marker.visible = false
	
	for marker in mixed_markers:
		marker.visible = false
	
	for marker in cover_markers:
		marker.visible = false
	
	# Display attack markers
	for i in range(attack_tiles.size()):
		attack_markers[i].position = attack_tiles[i].position
		attack_markers[i].visible = true
	
	# Display mixed markers
	for i in range(mixed_tiles.size()):
		mixed_markers[i].position = mixed_tiles[i].position
		mixed_markers[i].visible = true
	
	# Display cover markers
	for i in range(cover_tiles.size()):
		cover_markers[i].position = cover_tiles[i].position
		cover_markers[i].visible = true


func clear_attack_highlight():
	if attack_markers.size() > 0:
		for m in attack_markers:
			m.visible = false
	if mixed_markers.size() > 0:
		for n in mixed_markers:
			n.visible = false
	if cover_markers.size() > 0:
		for p in cover_markers:
			p.visible = false


func setup_fog():
	var deployment_tiles = GameManager.get_deployment_tiles(GameManager.local_team)
	for tile in WorldMap.map_as_dict.values():
		if tile in deployment_tiles:
			tile.fog.visible = false
	update_fog()


@rpc("any_peer", "call_local", "reliable")
func update_fog():
	var visible_tiles: Array[Tile] = []
	var deployment_tiles = GameManager.get_deployment_tiles(GameManager.local_team)
	var tiles
	var flying: bool = false
	
	for unit in GameManager.units_by_id.values():
		if unit.team != GameManager.local_team:
			continue
		if unit.occupied_tile == null:
			print("FOG: friendly unit has no occupied_tile")
			continue
		
		if unit.data.FLYING: 
			flying = true
		
		if unit.data.SCOUT:
			tiles = find_visible_tiles(unit.occupied_tile, VISION_RANGE + 1, flying)
		else:
			tiles = find_visible_tiles(unit.occupied_tile, VISION_RANGE, flying)
		
		for tile in tiles:
			visible_tiles.append(tile)
	
	# Update fog on every tile
	for tile in WorldMap.map_as_dict.values():
		tile.fog.visible = tile not in visible_tiles and tile not in deployment_tiles
	
	# Unit visibility
	for unit in GameManager.units_by_id.values():
		if unit.team == GameManager.local_team:
			unit.visible = true
		else:
			unit.visible = not unit.occupied_tile.fog.visible
	
	# Terrain visibility
	for tile in WorldMap.map_as_dict.values():
		if tile.terrain != null:
			tile.terrain_object.visible = not tile.fog.visible


func find_visible_tiles(start: Tile, vision_range: int, flying: bool) -> Array[Tile]:
	var visible_tiles: Array[Tile] = []
	var visited: Array[Tile] = []
	var queue = []
	
	queue.append({
		"tile": start,
		"distance": 0
	})
	visited.append(start)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_tile: Tile = current["tile"]
		var current_distance: int = current["distance"]
		var los = get_line_of_sight(start, current_tile)
		
		if los != LOSResult.BLOCKED or flying or (current_tile.occupier != null and current_tile.occupier.data.FLYING):
			visible_tiles.append(current_tile)
		
		
		if current_distance >= vision_range:
			continue
		
		for neighbor in current_tile.neighbors:
			if neighbor in visited:
				continue
			visited.append(neighbor)
			
			queue.append({
				"tile": neighbor,
				"distance": current_distance + 1
			})
	
	return visible_tiles

func get_line_of_sight(start: Tile, target: Tile, flying: bool = false) -> LOSResult:
	if start == target:
		return LOSResult.CLEAR
	
	var start_grid := Vector2i(start.pos_data.grid_position)
	var target_grid := Vector2i(target.pos_data.grid_position)
	var start_cube := _grid_to_cube(start_grid)
	var target_cube := _grid_to_cube(target_grid)
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3(0.0001, -0.0001, 0.0),
		Vector3(-0.0001, 0.0, 0.0001)
	]
	
	if not flying:
		var blocked_count := 0
		
		for offset in offsets:
			if _line_is_blocked(start_cube, target_cube, offset):
				blocked_count += 1
		
		if blocked_count == offsets.size():
			return LOSResult.BLOCKED
		elif blocked_count > 0:
			return LOSResult.PARTIAL_COVER
		
		return LOSResult.CLEAR
	
	return LOSResult.CLEAR


func _line_is_blocked(
	start_cube: Vector3i,
	target_cube: Vector3i,
	offset: Vector3,
	wall_tiles: Array[Tile] = []
) -> bool:
	var delta := target_cube - start_cube
	var steps := maxi(
		maxi(absi(delta.x), absi(delta.y)),
		absi(delta.z)
	)

	if steps == 0:
		return false

	var blocked := false

	for i in range(1, steps):
		var t := float(i) / float(steps)
		var point: Vector3 = Vector3(start_cube).lerp(
			Vector3(target_cube), t
		) + offset

		var cube := _cube_round(point)
		var grid := _cube_to_grid(cube)

		if not WorldMap.map_as_dict.has(Vector2(grid)):
			continue

		var tile: Tile = WorldMap.map_as_dict[Vector2(grid)]

		if tile.terrain != null and tile.terrain.blocks_los:
			blocked = true
			if not wall_tiles.has(tile):
				wall_tiles.append(tile)

	return blocked


func get_wall_tiles_on_line(start: Tile, target: Tile) -> Array[Tile]:
	var wall_tiles: Array[Tile] = []

	var start_cube := _grid_to_cube(
		Vector2i(start.pos_data.grid_position)
	)
	var target_cube := _grid_to_cube(
		Vector2i(target.pos_data.grid_position)
	)

	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3(0.0001, -0.0001, 0.0),
		Vector3(-0.0001, 0.0, 0.0001)
	]

	for offset in offsets:
		_line_is_blocked(
			start_cube,
			target_cube,
			offset,
			wall_tiles
		)

	return wall_tiles


func _grid_to_cube(grid: Vector2i) -> Vector3i:
	var q := grid.x
	var r := grid.y - floori(
		float(grid.x - posmod(grid.x, 2)) / 2.0
	)
	return Vector3i(q, r, -q - r)


func _cube_to_grid(cube: Vector3i) -> Vector2i:
	var col := cube.x
	var row := cube.y + floori(
		float(col - posmod(col, 2)) / 2.0
	)
	return Vector2i(col, row)


func _cube_round(cube: Vector3) -> Vector3i:
	var q := roundi(cube.x)
	var r := roundi(cube.y)
	var s := roundi(cube.z)
	
	var q_diff := absf(float(q) - cube.x)
	var r_diff := absf(float(r) - cube.y)
	var s_diff := absf(float(s) - cube.z)
	
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	else:
		s = -q - r
	
	return Vector3i(q, r, s)


func is_adjacent_to_enemy_melee(tile: Tile, team: int) -> bool:
	for neighbor in tile.neighbors:
		if neighbor.occupier != null:
			if neighbor.occupier.team != team and neighbor.occupier.data.MELEE:
				return true
	return false
