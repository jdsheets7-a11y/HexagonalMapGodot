extends CanvasLayer
class_name HUD

@onready var val = $Inspector/HBoxContainer/Values
@onready var army = $DeployPanel/VBoxContainer/ArmyList
@onready var deploy_panel = $DeployPanel


func _ready():
	GameManager.hud = self
	build_army()
	army.item_selected.connect(_on_army_item_selected)


func _process(_delta: float) -> void:
	$TurnCounter.text= "Round: " + str(GameManager.turn_counter)


#Update the stat inspector
func update_inspector(unit):
	var data : UnitData
	val.get_node("HealthVal").text = str(unit.health_remaining) \
	+ "/" + str(unit.total_health)
	val.get_node("ArmorVal").text = str(unit.data.armor)
	val.get_node("TroopsVal").text = str(unit.troops_remaining) \
	+ "/" + str(unit.data.troops)
	val.get_node("MovementVal").text = str(unit.movement_remaining) \
	+ "/" + str(unit.data.movement_range)
	val.get_node("DamageVal").text = str(unit.data.damage)
	val.get_node("AccuracyVal").text = str(unit.data.accuracy)
	val.get_node("ArmorPenVal").text = str(unit.data.armor_pen)
	val.get_node("RangeVal").text = str(unit.data.attack_range)
	val.get_node("AttacksVal").text = str(unit.data.attacks)
	
	$Inspector.visible = true


func _on_end_turn_pressed() -> void:
	GameManager.end_turn()


func hit_display(hit: bool, wound: bool):
	if hit and wound:
		$HitIndicator.color = Color(0.129, 0.612, 0.102, 1.0)
		$HitIndicator/HitLabel.text = "Hit!"
	elif hit and !wound:
		$HitIndicator.color = Color(0.682, 0.569, 0.0, 1.0)
		$HitIndicator/HitLabel.text = "Blocked"
	elif !hit:
		$HitIndicator.color = Color(0.637, 0.118, 0.0, 1.0)
		$HitIndicator/HitLabel.text = "Miss"
	
	$HitIndicator.visible = true
	await get_tree().create_timer(1).timeout
	$HitIndicator.visible = false


func build_army():
	army.clear()
	for unit in GameManager.army_list:
		army.add_item(unit.unit_name)


func _on_army_item_selected(index: int):
	HUDstate.selected_unit = GameManager.army_list[index]
	HUDstate.selected_unit_index = index
	print(HUDstate.selected_unit.unit_name + " selected")


func remove_unit():
	var index = HUDstate.selected_unit_index

	army.remove_item(index)
	GameManager.army_list.remove_at(index)
	HUDstate.selected_unit = null
	HUDstate.selected_unit_index = -1

func _on_ready_up_pressed() -> void:
	GameManager.deployment_ready()
