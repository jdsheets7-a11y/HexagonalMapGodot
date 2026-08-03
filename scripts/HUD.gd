extends CanvasLayer
class_name HUD

@onready var val = $Inspector/HBoxContainer/Values


func _ready():
	GameManager.hud = self


func _process(_delta: float) -> void:
	var team_text = ""
	
	match GameManager.game_state:
		GameManager.GameState.TEAM_1_TURN:
			team_text = "Team 1"
		GameManager.GameState.TEAM_2_TURN:
			team_text = "Team 2"
	
	$TurnCounter.text= "Turn: %d - %s" % [GameManager.turn_counter, team_text]


#Update the stat inspector
func update_inspector(unit):
	var data : UnitData
	val.get_node("HealthVal").text = str(unit.current_health) \
	+ "/" + str(unit.data.max_health)
	val.get_node("ArmorVal").text = str(unit.data.armor)
	val.get_node("TroopsVal").text = str(unit.current_troops) \
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


func _on_deploy_mode_pressed() -> void:
	if multiplayer.is_server():
		GameManager.set_game_state.rpc(GameManager.GameState.DEPLOYMENT)
	else:
		GameManager.request_game_state.rpc_id(1, GameManager.GameState.DEPLOYMENT)


func _on_player_turn_pressed() -> void:
	if multiplayer.is_server():
		GameManager.set_game_state.rpc(GameManager.GameState.TEAM_1_TURN)
	else:
		GameManager.request_game_state.rpc_id(1, GameManager.GameState.TEAM_1_TURN)

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
