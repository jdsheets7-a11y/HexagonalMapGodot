extends Node3D
class_name INTERACTION


@export var tile_cursor_scene: PackedScene
@export var unit_cursor_scene: PackedScene
@export var main_camera: Camera3D
@export var p_finder: Pathfinder
var selected_tile: Node3D
var selected_unit: Unit
var unit_moves: Array[Node3D]
var attack_tiles: Array[Node3D]
var tile_cursor: Node3D
var unit_cursor: Node3D
var occupied_tile: Tile



func _ready() -> void:
	if not tile_cursor or tile_cursor == null:
		tile_cursor = tile_cursor_scene.instantiate()
		add_child(tile_cursor)
	if not unit_cursor:
		unit_cursor = unit_cursor_scene.instantiate()
		add_child(unit_cursor)
	deselect()


func turn_start():
	for unit in get_tree().get_nodes_in_group("units"):
		unit.movement_remaining = unit.movement_range
		unit.has_moved = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos = get_viewport().get_mouse_position()
		var origin = main_camera.project_ray_origin(mouse_pos)
		var dir = main_camera.project_ray_normal(mouse_pos)
		var end = origin + dir * 1000
		var hit_object = raycast_at_mouse(origin, end)
		
		if not hit_object:
			return
		
		if Input.is_action_just_pressed("Click") and event.pressed:
			match GameManager.game_state:
				GameManager.GameState.DEPLOYMENT:
					GameManager.request_deploy_unit("RPG_UNIT", hit_object)
				_:
					attempt_select(hit_object)
				
		
		elif Input.is_action_just_pressed("RightClick"):
			if GameManager.game_state == GameManager.GameState.DEPLOYMENT:
				# Add any right click deplyment logic here
				
				
				return
			else:
				if hit_object.is_in_group("units"):
					var attack_tiles = p_finder.find_attackable_tiles(
						selected_unit.occupied_tile,
						selected_unit.data.attack_range)
					
					if not attack_tiles.has(hit_object.occupied_tile):
						print("Target out of range")
						return
						
					
					GameManager.request_attack(selected_unit, hit_object)
					
				else:
					if not p_finder.reachable_distances.has(hit_object):
						print("Tile is not reachable")
						return
					
					var distance = p_finder.reachable_distances[hit_object]
					print("Distance: ", distance)
					GameManager.request_move_unit(selected_unit, hit_object, distance)


func raycast_at_mouse(origin, end) -> Node3D:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var collision = get_world_3d().direct_space_state.intersect_ray(query)
		if collision and collision.has("collider"):
			var hit = collision.collider.get_parent()
			return hit
		else:
			deselect()
			return null


func attempt_select(hit):
	if hit.is_in_group("tiles"):
		highlight_tile(hit)
	elif hit.is_in_group("units"):
		select_unit(hit)


func deselect():
	hide_cursor(tile_cursor)
	hide_cursor(unit_cursor)
	unit_moves.clear()
	selected_unit = null
	p_finder.clear_highlight()
	p_finder.clear_attack_highlight()
	get_tree().current_scene.get_node("CameraParent/Camera3D/HUD/Inspector").visible = false


func select_unit(unit):
	deselect()
	
	selected_tile = null
	selected_unit = unit
	hide_cursor(tile_cursor)
	if unit is Unit:
		highlight_unit(unit)
		unit_moves = p_finder.find_reachable_tiles(unit.occupied_tile, unit.movement_remaining)
		p_finder.highlight_tile(unit_moves)
		attack_tiles = p_finder.find_reachable_tiles(unit.occupied_tile, unit.data.attack_range)
		p_finder.highlight_attack_tiles(attack_tiles)
		get_tree().current_scene.get_node("CameraParent/Camera3D/HUD").update_inspector(selected_unit)


func highlight_tile(tile):
	deselect()
	
	selected_unit = null
	selected_tile = tile
	hide_cursor(unit_cursor)
	move_cursor(tile_cursor, tile.global_position)
	tile_cursor.visible = true
	animate_cursor(tile_cursor)
	print(tile.biome)


func highlight_unit(unit):
	move_cursor(unit_cursor, unit.position)
	unit_cursor.visible = true


## move cursor with optional height difference
func move_cursor(cursor : Node3D, pos : Vector3, height : float = 0):
	cursor.position = pos
	if height != 0:
		tile_cursor.position.y += height


func animate_cursor(cursor : Node3D):
	var tween = get_tree().create_tween()
	var initial_scale = cursor.scale
	var target_scale = initial_scale * 1.15
	tween.set_trans(Tween.TRANS_SPRING)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cursor, "scale", target_scale, 0.175)
	tween.tween_property(cursor, "scale", initial_scale, 0.2)


func hide_cursor(cursor : Node3D):
	if cursor:
		move_cursor(cursor, Vector3.ZERO, -10)
		cursor.visible = false
