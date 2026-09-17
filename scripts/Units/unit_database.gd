# unit_database.gd
extends Node

const UNIT_SCENE = preload("res://scenes/Units/prototype_unit.tscn")


#Humans
const RPG = preload("res://Resources/Units/Humans/RPG.tres")
const TANK  = preload("res://Resources/Units/Humans/Tank.tres")
const SOLDIER = preload("res://Resources/Units/Humans/Soldier.tres")
const FLAMETHROWER = preload("res://Resources/Units/Humans/Flamethrower.tres")
const SNIPER = preload("res://Resources/Units/Humans/Sniper.tres")


#Robots
const RIPPERS = preload("res://Resources/Units/Robots/Rippers.tres")
const LAZER_MECH = preload("res://Resources/Units/Robots/Lazer_Mech.tres")
const DESTROYER = preload("res://Resources/Units/Robots/Destroyer.tres")
const AUTO_CANNON = preload("res://Resources/Units/Robots/Auto_Cannon.tres")


static var unit_catalog := {
	#Humans
	"RPG": RPG,
	"TANK": TANK,
	"FLAMETHROWER": FLAMETHROWER,
	"SOLDIER": SOLDIER,
	"SNIPER": SNIPER,
	
	
	#Robots
	"RIPPERS": RIPPERS,
	"LAZER_MECH": LAZER_MECH,
	"AUTO_CANNON": AUTO_CANNON,
	"DESTROYER": DESTROYER
}


static func get_unit(unit_type: String) -> UnitData:
	return unit_catalog.get(unit_type)
