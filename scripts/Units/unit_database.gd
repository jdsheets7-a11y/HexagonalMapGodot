# unit_database.gd
extends Node

const UNIT_SCENE = preload("res://scenes/Units/prototype_unit.tscn")

const RPG_UNIT = preload("res://Resources/Units/Humans/RPG.tres")
const TANK_UNIT  = preload("res://Resources/Units/Humans/Tank.tres")
const RIPPERS_UNIT = preload("res://Resources/Units/Robots/Rippers.tres")

static var unit_catalog := {
	"RPG_UNIT": RPG_UNIT,
	"TANK_UNIT": TANK_UNIT,
	"RIPPERS_UNIT": RIPPERS_UNIT
}

signal selected_unit(data)

static func get_unit(unit_type: String) -> UnitData:
	return unit_catalog.get(unit_type)
