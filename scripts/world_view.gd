extends Control
# Clip a scrolling world without moving the HUD or battle presentation.
var game
func _draw() -> void:
	if is_instance_valid(game) and game.mode == "explore": game.draw_exploration(self)
