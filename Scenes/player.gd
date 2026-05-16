extends CharacterBody2D

@export_category("Stats")
@export var speed: int = 400

var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _physics_process(_delta: float) -> void:
	movement_loop()
	update_animation()

func movement_loop() -> void:
	# Movimentação padrão
	move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = move_direction * speed
	move_and_slide()

func update_animation() -> void:
	# 1. Pega o vetor que aponta do personagem para o mouse (já normalizado entre -1 e 1)
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	
	# 2. Injeta a direção do mouse direto no "alvo" dos dois BlendSpaces.
	# A Godot vai olhar para esse vetor e escolher a animação certa automaticamente!
	animation_tree.set("parameters/Idle/blend_position", mouse_direction)
	animation_tree.set("parameters/Run/blend_position", mouse_direction)
	
	# 3. Alterna entre o estado de Correr e Parado baseado no movimento do teclado/analógico
	if move_direction != Vector2.ZERO:
		animation_playback.travel("Run")
	else:
		animation_playback.travel("Idle")
