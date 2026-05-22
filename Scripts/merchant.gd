extends Area2D

@export var dialog_box: Control # Drag your DialogBox node here in the Inspector
var player_in_range: bool = false

func _ready():
	global_position = Vector2(800, 250)

func _on_body_entered(body):
	if body.is_in_group("player"): # Add your player node to a "player" group first!
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		dialog_box.hide()

func _input(event):
	# Set up an "interact" action in Project Settings > Input Map (e.g. bind to E key)
	if event.is_action_pressed("interact") and player_in_range:
		dialog_box.visible = !dialog_box.visible
		if dialog_box.visible:
			dialog_box.get_node("dialogo").text = "Hehe! Quer compra umas tralha?"
