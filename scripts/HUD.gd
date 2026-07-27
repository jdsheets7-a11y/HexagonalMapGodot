extends CanvasLayer


@onready var vbox = $Inspector/VBoxContainer

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
	vbox.get_node("HBoxContainer/HealthVal").text = str(unit.current_health) \
	+ "/" + str(unit.data.max_health)
	vbox.get_node("HBoxContainer2/ArmorVal").text = str(unit.data.armor)
	vbox.get_node("HBoxContainer3/MovementVal").text = str(unit.movement_remaining) \
	+ "/" + str(unit.data.movement_range)
	vbox.get_node("HBoxContainer5/DamageVal").text = str(unit.data.damage)
	vbox.get_node("HBoxContainer6/AccuracyVal").text = str(unit.data.accuracy)
	vbox.get_node("HBoxContainer7/ArmorPenVal").text = str(unit.data.armor_pen)
	vbox.get_node("HBoxContainer8/RangeVal").text = str(unit.data.attack_range)
	vbox.get_node("HBoxContainer9/AttacksVal").text = str(unit.data.attacks)
	
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


func _on_inspection_button_pressed() -> void:
	$Inspection.visible = false
	
