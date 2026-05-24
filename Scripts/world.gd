extends Node2D

@onready var forest = $Forest
@onready var player = $Player

var raiding_village_scene = preload("res://Scenes/raiding_village.tscn")

func _ready():
	if forest:
		forest.connect("player_entered_transition", Callable(self, "_on_change_map"))

func _on_change_map():
	# Em vez de rodar o código aqui, nós "adiamos" (defer) a execução
	# para o momento em que a engine de física terminar o que está fazendo.
	call_deferred("_mudar_mapa_seguro")

# O código que você já tinha vem todo para esta nova função
func _mudar_mapa_seguro():
	# 1. Limpa os inimigos/NPCs
	var entidades_para_limpar = get_tree().get_nodes_in_group("limpar_na_transicao")
	for entidade in entidades_para_limpar:
		entidade.queue_free()
	
	# 2. Remove a floresta atual da memória
	if is_instance_valid(forest):
		forest.queue_free()
	
	# 3. Instancia a nova vila
	var new_map = raiding_village_scene.instantiate()
	add_child(new_map)
	
	# 4. Coloca o mapa no fundo
	move_child(new_map, 0)
	
	# 5. NOVO: Puxa o ponto de spawn e teletransporta o jogador
	var spawn = new_map.get_node("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
