extends CanvasLayer
class_name HUD

@onready var val = $Inspector/VBoxContainer/HBoxContainer/Values
@onready var army = $DeployPanel/VBoxContainer/ArmyList
@onready var deploy_panel = $DeployPanel
@onready var keywords_grid: GridContainer = $Inspector/VBoxContainer/Keywords

var stamped_font = preload("res://assets/Fonts/Spaced_out_Stamped.tres")
var stamped_material = preload("res://assets/Shaders/New_Indent.gdshader")


const KEYWORD_COLORS = {
	"FLYING": Color("#4DA6FF"),
	"MELEE": Color("#E74C3C"),
	"INFANTRY": Color("#75C46B"),
	"CONTROL": Color("#B18CFF"),
	"NIMBLE": Color("#F4D35E"),
	"SCOUT": Color("#42D6D6"),
	"IMPACT": Color("#FF9F43"),
	"EVASIVE": Color("#66CDAA"),
	"EVASIVE2": Color("#48A999"),
	"BULKY": Color("#C49A6C"),
	"BULKY2": Color("#96704B")
}

func _ready():
	GameManager.hud = self
	build_army()
	army.item_selected.connect(_on_army_item_selected)


func _process(_delta: float) -> void:
	$TurnCounter.text= "Round: " + str(GameManager.turn_counter)


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
	
	update_keyword_display(unit.active_keywords)


func update_keyword_display(active_keywords: Array):
	for child in keywords_grid.get_children():
		keywords_grid.remove_child(child)
		child.queue_free()
		
	for keyword in active_keywords:
		var color: Color = KEYWORD_COLORS.get(keyword, Color.WHITE)
		if active_keywords.size() == 1:
			keywords_grid.columns = 1
		else:
			keywords_grid.columns = 2
		
		var label = Label.new()
		label.text = keyword
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var material = ShaderMaterial.new()
		material.shader = stamped_material
		material.set_shader_parameter("face_color", color)
		
		label.material = material
		label.add_theme_font_override("font", stamped_font)
		label.add_theme_font_size_override("font_size", 48)
		
		
		keywords_grid.add_child(label)


func _on_end_turn_pressed() -> void:
	GameManager.end_turn()


func hit_display(hit: bool, wound: bool, crit: bool):
	if hit and wound and crit:
		$HitIndicator.color = Color(0.129, 0.612, 0.102, 1.0)
		$HitIndicator/HitLabel.text = "Crit!"
		$HitIndicator/HitLabel.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
	elif hit and wound:
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
	$HitIndicator/HitLabel.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))


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
