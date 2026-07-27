extends Node

# Dependencies
@export var settings : GenerationSettings
@export_category("Dependencies")
@export var object_placer : ObjectPlacer
@export var tile_parent : Node3D

# Test-only!
@export var pfinder : Pathfinder
@export var proto_unit : PackedScene


## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	if multiplayer.is_server():
		init_seed()
		GameManager.send_world_seed.rpc(settings.map_seed)
		generate_world()



func start_generation(seed: int):
	settings.map_seed = seed
	init_seed()
	generate_world()


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
