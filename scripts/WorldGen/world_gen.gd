extends Node

@export var settings: GenerationSettings

@export_category("Dependencies")
@export var object_placer: ObjectPlacer
@export var tile_parent: Node3D
@export var p_finder: PATHFINDER

@export var proto_unit: PackedScene
@export var wall_scene: PackedScene




func _ready() -> void:
	#init_seed()
	#GameManager.send_world_seed.rpc(settings.map_seed)
	if multiplayer.is_server():
		print("Ready to generate world")
		generate_authored_world()
		print("World generated!")
		
		GameManager.start_authored_world.rpc()
		
		GameManager.setup_deployment_zone()
		show_deployment_zone()


func start_generation(seed: int):
	settings.map_seed = seed
	init_seed()
	generate_world()
	GameManager.setup_deployment_zone()
	show_deployment_zone()


# Randomize if no seed has been set
func init_seed():
	if settings.map_seed == 0 or settings.map_seed == null:
		print("Randomizing seed")
		settings.map_seed = randi()

	settings.biome_noise.seed = settings.map_seed
	settings.heightmap_noise.seed = settings.map_seed
	settings.ocean_noise.seed = settings.map_seed



## Start of world_generation
func generate_world():
	
	## Get all positions through the gridmapper
	var mapper = GridMapper.new()
	var positions = mapper.calculate_map_positions(settings)
	
	
	## Create the tiles
	var factory = TileFactory.new()
	factory.init_factory(settings, tile_parent)
	var map = factory.create_map(positions)
	WorldMap.set_map(map)
	
	
	## Fill all gaps
	if settings.modify_height:
		factory.modify_terrain()
	
	
	## Spawn villages
	if settings.spawn_villages:
		var placeable = get_placeable_tiles()
		object_placer.place_villages(placeable, settings.spacing)


## Ignore buffer and ocean to return for object placer
func get_placeable_tiles() -> Array[Tile]:
	var placeable_tiles : Array[Tile] = []
	for tile : Tile in WorldMap.map:
		if tile.pos_data.buffer or not tile.placeable:
			continue
		placeable_tiles.append(tile)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles


func show_deployment_zone():
	var deployment_tiles = GameManager.get_deployment_tiles(GameManager.local_team)
	p_finder.highlight_deployment_tiles(deployment_tiles)
	p_finder.setup_fog()


var wall_array: Array[Vector2] = [
	Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(-1, 3),
	Vector2(0, -1), Vector2(0, -2), Vector2(0, -3), Vector2(1, -4),
	Vector2(4, 3), Vector2(5, 3), Vector2(6, 4), Vector2(7, 4),
	Vector2(-7, -3), Vector2(-6, -2), Vector2(-5, -3), Vector2(-4, -2),
	Vector2(-8, 4), Vector2(-7, 4), Vector2(-5, 3),
	Vector2(5, -4), Vector2(6, -3), Vector2(7, -2), Vector2(6, -1),
	Vector2(-3, -6), Vector2(-2, -6), Vector2(4, 7), Vector2(5, 7),
	Vector2(-5, 7), Vector2(-4, 7), Vector2(-3, 7),
	Vector2(2, 5), Vector2(-6, 1), Vector2(3, -1), Vector2(8, 1)
	]


func generate_authored_world():
	var mapper = GridMapper.new()
	var positions = mapper.calculate_map_positions(settings)
	
	var factory = TileFactory.new()
	factory.init_factory(settings, tile_parent)
	var map = factory.create_authored_map(positions)
	
	WorldMap.set_map(map)
	
	for wall in wall_array:
		place_test_wall(wall)



func place_test_wall(location: Vector2):
	var tile: Tile = WorldMap.map_as_dict[location]
	var wall = wall_scene.instantiate()
	wall.position = tile.position
	tile.terrain = wall.terrain
	tile.terrain_object = wall
	tile_parent.add_child(wall)
