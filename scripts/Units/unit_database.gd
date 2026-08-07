# unit_database.gd
extends Node

const UNIT_SCENE = preload("res://scenes/Units/prototype_unit.tscn")


#Humans
const RPG_UNIT = preload("res://Resources/Units/Humans/RPG.tres")
const TANK_UNIT  = preload("res://Resources/Units/Humans/Tank.tres")
const SOLDIER_UNIT = preload("res://Resources/Units/Humans/Soldier.tres")
const FLAMETHROWER_UNIT = preload("res://Resources/Units/Humans/Flamethrower.tres")
const SNIPER_UNIT = preload("res://Resources/Units/Humans/Sniper.tres")


#Robots
const RIPPERS_UNIT = preload("res://Resources/Units/Robots/Rippers.tres")



static var unit_catalog := {
	#Humans
	"RPG_UNIT": RPG_UNIT,
	"TANK_UNIT": TANK_UNIT,
	"FLAMETHROWER_UNIT": FLAMETHROWER_UNIT,
	"SOLDIER_UNIT": SOLDIER_UNIT,
	"SNIPER_UNIT": SNIPER_UNIT,
	
	
	#Robots
	"RIPPERS_UNIT": RIPPERS_UNIT
}

signal selected_unit(data)

static func get_unit(unit_type: String) -> UnitData:
	return unit_catalog.get(unit_type)
