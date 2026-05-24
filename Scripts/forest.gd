extends Node2D

# Cria um sinal que será ouvido pelo World
signal player_entered_transition

func _on_transition_zone_body_entered(body) -> void:
	if body.name == "Player":
		emit_signal("player_entered_transition")
