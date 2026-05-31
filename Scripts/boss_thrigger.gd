extends Area2D

# Aqui nós vamos linkar o Dragão pelo Inspetor
@export var boss: CharacterBody2D 

func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem entrou na área foi o Player
	# (Ajuste "Player" para o nome exato do nó do seu jogador se for diferente)
	if body.name == "Player" or body.is_in_group("player"):
		if boss and boss.has_method("ativar_chefao"):
			boss.ativar_chefao(body) # Passa a referência do player para o boss
			queue_free() # Deleta o trigger para não ativar duas vezes
