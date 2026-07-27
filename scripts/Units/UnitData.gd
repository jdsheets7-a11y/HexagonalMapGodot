extends Resource
class_name UnitData


@export var unit_name : String
@export var max_health: int
@export var movement_range: int 
@export var accuracy: int
@export var damage: int
@export var armor_pen: int
@export var attacks: int
@export var attack_range: int
@export var armor: int
@export var troops: int
@export var point_cost: int

@export var model: PackedScene

#Tags
@export var infantry: bool
@export var control: bool
