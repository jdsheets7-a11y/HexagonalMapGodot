# unit_database.gd
extends Node

const UNIT_SCENE = preload("res://scenes/Units/prototype_unit.tscn")

const RPG_UNIT = preload("res://Resources/Units/Humans/RPG.tres")
const TANK_UNIT  = preload("res://Resources/Units/Humans/Tank.tres")

static var units := {
	"RPG_UNIT": RPG_UNIT,
	"TANK_UNIT": TANK_UNIT,
}

static func get_unit(unit_type: String) -> UnitData:
	return units.get(unit_type)
