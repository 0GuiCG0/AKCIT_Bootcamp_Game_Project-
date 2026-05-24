extends Area2D

@onready var sprite: Sprite2D = $livro

func _ready() -> void:
	# Conecta o sinal de entrar na área
	body_entered.connect(_on_body_entered)
	
	# Efeito do livro flutuando magicamente
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	# 1. Primeiro verificamos se a colisão está a acontecer de todo
	print("ALERTA: Algo tocou no livro! Nome do corpo: ", body.name)
	
	# 2. Verificamos se o jogo reconhece que é o jogador
	if body.is_in_group("player"):
		print("SUCESSO: O jogo sabe que é o Player!")
		
		# 3. Verificamos se a função foi bem criada no Player
		if body.has_method("aprender_smite"):
			print("SUCESSO: A função foi encontrada. A aprender magia e a destruir livro...")
			body.aprender_smite()
			queue_free()
		else:
			print("ERRO: O Player está no grupo, mas NÃO tem a função 'aprender_smite'!")
	else:
		print("ERRO: O corpo tocou no livro, mas NÃO está no grupo 'player'.")
