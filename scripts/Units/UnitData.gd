extends Resource
class_name UnitData


@export var unit_name : String
@export var health_per_troop: int
@export var troops: int
@export var movement_range: int
@export var speed: int
@export var accuracy: int
@export var damage: int
@export var armor_pen: int
@export var attacks: int
@export var attack_range: int
@export var min_attack_range: int
@export var armor: int

@export var point_cost: int
@export var model: PackedScene
@export var icon: Texture2D


enum Faction {
	HUMAN,
	ROBOT
}

@export var faction = Faction.HUMAN

#Tags
@export var INFANTRY: bool
@export var CONTROL: bool
@export var MELEE: bool
@export var SWARM: bool
