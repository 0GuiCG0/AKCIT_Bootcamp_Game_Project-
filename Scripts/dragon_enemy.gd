extends CharacterBody2D

# --- CONFIGURAÇÕES DA ARENA RETANGULAR ---
# X = Distância nas laterais (esquerda/direita) | Y = Distância vertical (cima/baixo)
@export var tamanho_zona: Vector2 = Vector2(200.0, 100.0)       
@export var velocidade_patrulha: float = 140.0 
@export var tempo_na_aresta: float = 3.5      

# --- CONFIGURAÇÕES VISUAIS ---
@export var velocidade_batimento: float = 6.0 
@export var intensidade_flutuar: float = 5.0  
@export var velocidade_respiro: float = 3.5   

# --- MÁQUINA DE ESTADOS ---
enum Estado { PATRULHA, TELEPORTE }
var estado_atual: Estado = Estado.PATRULHA

var player: Node2D = null
var ativo: bool = false
var tempo_anim: float = 0.0
var cronometro_aresta: float = 0.0

var no_lado_esquerdo: bool = true   
var indo_para_cima: bool = true     

# Referências
@onready var sprite: Sprite2D = $dragon_sprite
@onready var base_scale: Vector2 = sprite.scale
@onready var base_pos: Vector2 = sprite.position

func _physics_process(delta: float) -> void:
	if not ativo or not player:
		aplicar_efeito_visual()
		return

	match estado_atual:
		Estado.PATRULHA:
			logica_patrulha(delta)
			move_and_slide()
			atualizar_animacao_aresta()
		Estado.TELEPORTE:
			velocity = Vector2.ZERO


func logica_patrulha(delta: float) -> void:
	aplicar_efeito_visual() 

	cronometro_aresta += delta
	if cronometro_aresta >= tempo_na_aresta:
		cronometro_aresta = 0.0
		iniciar_teleporte()
		return

	# Usa tamanho_zona.x para a distância lateral
	var alvo_x = player.global_position.x + (-tamanho_zona.x if no_lado_esquerdo else tamanho_zona.x)
	
	# Usa tamanho_zona.y para os limites de cima e de baixo
	if indo_para_cima and global_position.y <= player.global_position.y - tamanho_zona.y:
		indo_para_cima = false
	elif not indo_para_cima and global_position.y >= player.global_position.y + tamanho_zona.y:
		indo_para_cima = true
		
	var alvo_y = player.global_position.y + (-tamanho_zona.y if indo_para_cima else tamanho_zona.y)
	
	var direcao = global_position.direction_to(Vector2(alvo_x, alvo_y))
	velocity = direcao * velocidade_patrulha


func iniciar_teleporte() -> void:
	estado_atual = Estado.TELEPORTE
	
	# 1. EFEITO DE SUMIR (Vanish)
	var tween_sumir = create_tween()
	tween_sumir.set_parallel(true)
	
	tween_sumir.tween_property(sprite, "scale", Vector2(0.0, base_scale.y * 1.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween_sumir.tween_property(sprite, "modulate:a", 0.0, 0.2)
	
	await tween_sumir.finished
	
	# 2. TELEPORTE MATEMÁTICO 
	no_lado_esquerdo = not no_lado_esquerdo
	indo_para_cima = not indo_para_cima 
	
	# Lembrar de usar tamanho_zona.x aqui também
	var alvo_x = player.global_position.x + (-tamanho_zona.x if no_lado_esquerdo else tamanho_zona.x)
	global_position.x = alvo_x
	
	sprite.flip_h = no_lado_esquerdo
	
	# 3. EFEITO DE REAPARECER (Spawn)
	var tween_aparecer = create_tween()
	tween_aparecer.set_parallel(true)
	
	tween_aparecer.tween_property(sprite, "scale", base_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_aparecer.tween_property(sprite, "modulate:a", 1.0, 0.3)
	
	await tween_aparecer.finished
	
	# 4. VOLTA PARA PATRULHA
	estado_atual = Estado.PATRULHA


func atualizar_animacao_aresta() -> void:
	sprite.frame = 2
	
	if no_lado_esquerdo:
		sprite.flip_h = true
	else:
		sprite.flip_h = false


func aplicar_efeito_visual() -> void:
	var tempo = Time.get_ticks_msec() / 1000.0 * velocidade_respiro
	sprite.position.y = base_pos.y + sin(tempo) * intensidade_flutuar
	sprite.scale.x = base_scale.x * (1.0 + cos(tempo) * 0.02)
	sprite.scale.y = base_scale.y * (1.0 + sin(tempo) * 0.03)


func ativar_chefao(player_ref: Node2D) -> void:
	player = player_ref
	ativo = true
	cronometro_aresta = 0.0
	
	# Garante que o sprite está no estado inicial perfeito antes de animar
	sprite.modulate.a = 1.0 
	sprite.scale = base_scale
	
	# Em vez de começar no estado PATRULHA, já chamamos o teleporte direto!
	iniciar_teleporte()
