extends CharacterBody2D

@export_category("Animação Procedural")
@export var walk_anim_speed: float = 18.0 
@export var walk_anim_angle: float = 0.15 
@export var walk_anim_bounce: float = 5.0 
var walk_timer: float = 0.0
var sprite_base_position: Vector2

@export_category("Movement Stats")
@export var speed: int = 400

@export_category("Player Stats")
@export var max_hp: int = 100
@export var max_mana: int = 50
@export var max_xp: int = 100

@export_category("Desbloqueios de Habilidade")
@export var smite_desbloqueado: bool = false # Começa falso!

@export_category("Dano dos Ataques")
@export var dano_slash: int = 15      # Dano editável no Inspetor
@export var dano_poderoso: int = 35   # Dano editável no Inspetor
@export var velocidade_ataque: float = 1.5 # 1.0 é o normal. 1.5 é 50% mais rápido. 2.0 é o dobro.
var slash_ativo: bool = false # Trava de segurança para o Slash
var smite_ativo: bool = false # Trava de segurança para o Smite

# --- Referências de Ataque (Adicione os Area2D na sua cena!) ---
@onready var pivot_ataque: Node2D = $PivotAtaque
@onready var smite_node: Node2D = $PivotAtaque/Smite

# ATENÇÃO: Você precisa criar nós Area2D na sua cena para os ataques detectarem os inimigos.
# Ajuste os caminhos abaixo conforme o nome dos nós na sua cena.
@onready var area_slash: Area2D = $PivotAtaque/Slash/HitboxSlash
@onready var area_smite: Area2D = $PivotAtaque/Smite/HitboxSmite

@export_category("Mecânicas de Tempo / Custos")
@export var dreno_hp_por_segundo: float = 0.0 
@export var regeneracao_mana_por_segundo: float = 3.0 
@export var custo_disparo_poderoso: int = 15          
@export var tempo_recarga_slash: float = 0.4 
var pode_atacar: bool = true 

var current_hp: float 
var current_mana: float
var current_xp: float

var move_direction: Vector2 = Vector2.ZERO


@onready var animation_player: AnimationPlayer = $AnimationPlayer 

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var sprite: Sprite2D = $Player 

# --- Referências da UI ---
@onready var hud_hp: ProgressBar = $HUD/hp
@onready var hud_mana: ProgressBar = $HUD/holy_mana
@onready var hud_xp: ProgressBar = $HUD/xp

# --- Referências dos Textos ---
@onready var txt_hp: Label = $HUD/hp/Texto
@onready var txt_mana: Label = $HUD/holy_mana/Texto
@onready var txt_xp: Label = $HUD/xp/Texto
@onready var txt_gold: Label = $HUD/gold_pouch/Texto


func _ready() -> void:
	$PivotAtaque/Slash/HitboxSlash/CollisionShape2D.set_deferred("disabled", true)
	$PivotAtaque/Smite/HitboxSmite/CollisionShape2D.set_deferred("disabled", true)
	sprite_base_position = sprite.position
	current_hp = max_hp
	current_mana = max_mana
	current_xp = 0
	
	hud_hp.max_value = max_hp
	hud_hp.value = current_hp
	hud_mana.max_value = max_mana
	hud_mana.value = current_mana
	hud_xp.max_value = max_xp
	hud_xp.value = GameManager.xp
	smite_node.set_as_top_level(true)
	GameManager.gold_alterado.connect(_atualizar_texto_gold)
	GameManager.xp_alterada.connect(_on_game_manager_xp_alterada)
	_atualizar_texto_gold(GameManager.gold) 


func _physics_process(delta: float) -> void:
	movement_loop()
	update_animation(delta)
	
	# --- SISTEMA DE ATAQUES ---
	if pode_atacar:
		if Input.is_action_just_pressed("ataque_slash"):
			realizar_ataque_slash()
			
		elif Input.is_action_just_pressed("ataque_poderoso"):
			tentar_disparo_poderoso()


func _process(delta: float) -> void:
	if dreno_hp_por_segundo > 0:
		current_hp = clamp(current_hp - (dreno_hp_por_segundo * delta), 0, max_hp)
		hud_hp.value = current_hp
		
	if current_mana < max_mana:
		current_mana = clamp(current_mana + (regeneracao_mana_por_segundo * delta), 0, max_mana)
		hud_mana.value = current_mana

	# Removemos as linhas de texto daqui e chamamos a nova função:
	atualizar_textos_hud()


# NOVO: Função isolada para atualizar textos! O Mercador vai usar isso.
func atualizar_textos_hud() -> void:
	txt_hp.text = "%d / %d" % [round(hud_hp.value), hud_hp.max_value]
	txt_mana.text = "%d / %d" % [round(hud_mana.value), hud_mana.max_value]
	txt_xp.text = "%d / %d" % [round(hud_xp.value), hud_xp.max_value] # Lê a barra atualizada


func movement_loop() -> void:
	move_direction = Input.get_vector("left", "right", "up", "down")
	velocity = move_direction * speed
	move_and_slide()


func update_animation(delta: float) -> void:
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	
	if mouse_direction.x != 0:
		sprite.flip_h = (mouse_direction.x > 0) 
	
	# Só atualiza a árvore de animação se ela estiver ATIVA e o jogador puder atacar
	if pode_atacar and animation_tree.active:
		animation_tree.set("parameters/Idle/blend_position", mouse_direction)
		animation_playback.travel("Idle")
	
	if move_direction != Vector2.ZERO:
		walk_timer += delta
		sprite.rotation = sin(walk_timer * walk_anim_speed) * walk_anim_angle
		sprite.position.y = sprite_base_position.y - abs(cos(walk_timer * walk_anim_speed)) * walk_anim_bounce
	else:
		_reset_sprite_transform(delta)


func _reset_sprite_transform(delta: float) -> void:
	walk_timer = 0.0
	sprite.rotation = lerp(sprite.rotation, 0.0, delta * 15.0)
	sprite.position.y = lerp(sprite.position.y, sprite_base_position.y, delta * 15.0)


func _atualizar_texto_gold(novo_total: int) -> void:
	txt_gold.text = "Gold: %d" % novo_total


# ==========================================
# Mecânicas de Ataque (Modo Blindado via Código)
# ==========================================

func realizar_ataque_slash() -> void:
	if not pode_atacar: return 
	pode_atacar = false
	
	animation_tree.active = false
	pivot_ataque.look_at(get_global_mouse_position())
	
	# 1. ATIVA o ataque (Física e Trava)
	slash_ativo = true
	$PivotAtaque/Slash/HitboxSlash/CollisionShape2D.set_deferred("disabled", false)
	
	animation_player.play("attackslash", -1, velocidade_ataque)
	
	# 2. Mantém o dano ativo apenas durante o golpe (ex: 0.2 segundos)
	await get_tree().create_timer(0.2).timeout
	
	# 3. DESATIVA o ataque imediatamente, independente da animação
	slash_ativo = false
	$PivotAtaque/Slash/HitboxSlash/CollisionShape2D.set_deferred("disabled", true)
	
	await animation_player.animation_finished
	animation_tree.active = true
	pode_atacar = true


func tentar_disparo_poderoso() -> void:
	if not pode_atacar: return 
	
	# NOVO: Trava do livro!
	if not smite_desbloqueado:
		print("Você ainda não aprendeu o ataque poderoso!")
		return
	
	if current_mana >= custo_disparo_poderoso:
		pode_atacar = false
		
		animation_tree.active = false
		pivot_ataque.rotation = 0
		smite_node.global_position = get_global_mouse_position()
		gastar_mana(custo_disparo_poderoso)
		
		# 1. ATIVA o ataque (Física e Trava)
		smite_ativo = true
		$PivotAtaque/Smite/HitboxSmite/CollisionShape2D.set_deferred("disabled", false)
		
		animation_player.play("attackholy", -1, velocidade_ataque)
		
		# 2. Mantém o dano ativo (ajuste o tempo se a explosão do smite for mais longa)
		await get_tree().create_timer(0.3).timeout
		
		# 3. DESATIVA o ataque imediatamente
		smite_ativo = false
		$PivotAtaque/Smite/HitboxSmite/CollisionShape2D.set_deferred("disabled", true)
		
		await animation_player.animation_finished
		animation_tree.active = true
		pode_atacar = true
	else:
		print("Sem mana!")


# ==========================================
# Detecção de Sinais (Hitboxes)
# ==========================================

func _on_hitbox_slash_body_entered(body: Node2D) -> void:
	# Só dá dano SE a trava foi liberada pelo clique do mouse
	if slash_ativo and body != self and body.has_method("tomar_dano"):
		body.tomar_dano(dano_slash)

func _on_hitbox_smite_body_entered(body: Node2D) -> void:
	# Só dá dano SE a trava foi liberada pelo clique do mouse
	if smite_ativo and body != self and body.has_method("tomar_dano"):
		body.tomar_dano(dano_poderoso)


# ==========================================
# Função Universal para Causar Dano
# ==========================================

func aplicar_dano(area_de_ataque: Area2D, quantidade_de_dano: int) -> void:
	# Verifica se a área existe
	if not is_instance_valid(area_de_ataque):
		return
		
	# Pega todos os corpos que estão dentro da área do ataque naquele exato frame
	var corpos_atingidos = area_de_ataque.get_overlapping_bodies()
	
	for corpo in corpos_atingidos:
		# Verifica se o corpo não é o próprio player e se possui a função de tomar dano
		if corpo != self and corpo.has_method("tomar_dano"):
			corpo.tomar_dano(quantidade_de_dano)


# ==========================================
# Funções de Impacto/Modificação da HUD
# ==========================================

func tomar_dano(quantidade: int) -> void:
	current_hp -= quantidade
	current_hp = clamp(current_hp, 0, max_hp)
	
	var tween = create_tween()
	tween.tween_property(hud_hp, "value", current_hp, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if current_hp <= 0:
		morrer()


func morrer() -> void:
	print("O jogador morreu! Resetando o universo...")
	set_physics_process(false)
	set_process(false)
	await get_tree().create_timer(1.0).timeout 
	get_tree().reload_current_scene()


func gastar_mana(quantidade: int) -> void:
	current_mana -= quantidade
	current_mana = clamp(current_mana, 0, max_mana)
	
	var tween = create_tween()
	tween.tween_property(hud_mana, "value", current_mana, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ==========================================
# Lógica de XP e Level Up (Agora com Sobra e Múltiplos Níveis!)
# ==========================================

func _on_game_manager_xp_alterada(nova_xp: float) -> void:
	# Anima a barra enchendo
	var tween = create_tween()
	tween.tween_property(hud_xp, "value", nova_xp, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Verifica se atingiu ou passou o limite
	if GameManager.xp >= max_xp:
		# Espera a barrinha terminar de encher visualmente antes de fazer o Level Up
		await tween.finished 
		processar_level_up()

func processar_level_up() -> void:
	var subiu_nivel = false
	
	# O 'while' garante que se você ganhar 1000 de XP, ele vai subindo de nível 
	# e deduzindo o custo repetidas vezes até sobrar só o "troco"
	while GameManager.xp >= max_xp:
		GameManager.xp -= max_xp # Tira a XP que foi gasta para este nível, mas GUARDA a sobra
		max_xp += 50             # Aumenta a dificuldade do próximo
		max_hp += 10             # Bônus do nível
		subiu_nivel = true
	
	# Se subiu pelo menos um nível, fazemos a festa:
	if subiu_nivel:
		current_hp = max_hp
		
		# Atualiza os limites máximos na UI
		hud_hp.max_value = max_hp
		hud_xp.max_value = max_xp
		
		# Anima a barra caindo pro 0 e depois subindo até o "troco" de XP que sobrou
		var tween = create_tween()
		tween.tween_property(hud_xp, "value", 0, 0.2)
		tween.tween_property(hud_xp, "value", GameManager.xp, 0.3)
		tween.parallel().tween_property(hud_hp, "value", current_hp, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		# Força o texto a atualizar a nova meta
		atualizar_textos_hud()
		print("Level Up! XP Sobrante mantida: ", GameManager.xp)

# ==========================================
# Desbloqueios Mágicos
# ==========================================

func aprender_smite() -> void:
	smite_desbloqueado = true
	print("MAGIA APRENDIDA: Você desbloqueou o Smite!")
	# Dica: No futuro você pode colocar um som épico tocando aqui!dda
