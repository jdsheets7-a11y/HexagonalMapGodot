extends CanvasLayer


func _process(delta: float) -> void:
	var team_text = ""
	
	match GameManager.game_state:
		GameManager.GameState.TEAM_1_TURN:
			team_text = "Team 1"
		GameManager.GameState.TEAM_2_TURN:
			team_text = "Team 2"
	
	$TurnCounter.text= "Turn: %d - %s" % [GameManager.turn_counter, team_text]


func _on_end_turn_pressed() -> void:
	GameManager.end_turn()


func _on_deploy_mode_pressed() -> void:
	GameManager.game_state = GameManager.GameState.DEPLOYMENT


func _on_player_turn_pressed() -> void:
	GameManager.game_state = GameManager.GameState.TEAM_1_TURN
