extends CanvasLayer



func end_turn():
	for unit in get_tree().get_nodes_in_group("units"):
		unit.movement_remaining = unit.movement_range
		unit.has_moved = false
		unit.attacks_remaining = unit.attacks


func _on_end_turn_pressed() -> void:
	end_turn()
