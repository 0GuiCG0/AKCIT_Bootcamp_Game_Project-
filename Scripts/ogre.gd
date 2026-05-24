extends StaticBody2D # Agora é um StaticBody2D para bloqueio absoluto

@export var speed: float = 100.0
@export var rotation_speed: float = 3.0 
@export var attack_range: float = 50.0 

@export_category("Combate")
@export var max_hp: int = 50 # Vida máxima do ogro
@export var xp_recompensa: int = 35 # Quanto de XP o Ogro vai dar ao morrer
var hp: int = 50 # Vida atual do ogro
@export var attack_damage: int = 20 
@export var attack_cooldown: float = 1.5

# --- Variáveis para a Animação Procedural de Caminhada ---
@export var walk_anim_speed: float = 15.0 
@export var walk_anim_angle: float = 0.15 
@export var walk_anim_bounce: float = 5.0 
var walk_timer: float = 0.0
var sprite_base_position: Vector2 
# ---------------------------------------------------------

var player: Node2D = null
var is_chasing: bool = false
var is_attacking: bool = false 
var can_attack: bool = true 
var invulneravel: bool = false # NOVO: Controle de invulnerabilidade

# Lista de quem está dentro da área vermelha
var alvos_no_ataque: Array[Node2D] = [] 

@onready var sprite = $Sprite2D
@onready var vision_area = $FOV
@onready var anim_player = $AnimationPlayer 
@onready var attack_area = $AreaAttack      

func _ready():
	sprite_base_position = sprite.position
	
	vision_area.body_entered.connect(_on_see_player_body_entered)
	vision_area.body_exited.connect(_on_see_player_body_exited)
	
	# Reconectando os sinais da área de ataque via CÓDIGO!
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func _process(delta):
	vision_area.scale = Vector2.ONE 
	
	# --- 1. ATUALIZAÇÃO DA ROTAÇÃO (Roda SEMPRE, mesmo atacando!) ---
	if is_chasing and player and is_instance_valid(player):
		# O FOV continua seguindo o jogador com o ajuste dele
		vision_area.rotation = global_position.angle_to_point(player.global_position) + PI
		
		# A área de ataque olha DIRETAMENTE para o jogador sem parar
		attack_area.look_at(player.global_position)
		
		# Atualiza o lado da sprite continuamente
		var direction = global_position.direction_to(player.global_position)
		if direction.x != 0:
			sprite.flip_h = (direction.x > 0)
	else:
		# Patrulha/Giro livre quando está parado
		vision_area.rotation += rotation_speed * delta
		var fov_direction = Vector2.LEFT.rotated(vision_area.rotation)
		sprite.flip_h = (fov_direction.x > 0)
		
		# Ataque acompanha o lado da sprite
		attack_area.rotation = PI if sprite.flip_h else 0.0

	# --- 2. BLOQUEIO DE ATAQUE (Agora só impede a movimentação de andar!) ---
	if is_attacking:
		return
	
	# --- 3. LÓGICA DE MOVIMENTAÇÃO ---
	if is_chasing and player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > attack_range:
			var direction = global_position.direction_to(player.global_position)
			move_and_collide(direction * speed * delta)
			
			walk_timer += delta
			sprite.rotation = sin(walk_timer * walk_anim_speed) * walk_anim_angle
			sprite.position.y = sprite_base_position.y - abs(cos(walk_timer * walk_anim_speed)) * walk_anim_bounce
		else:
			_reset_sprite_transform(delta)
			if can_attack:
				executar_ataque()
	else:
		_reset_sprite_transform(delta)

func _reset_sprite_transform(delta):
	walk_timer = 0.0
	sprite.rotation = lerp(sprite.rotation, 0.0, delta * 10.0)
	sprite.position.y = lerp(sprite.position.y, sprite_base_position.y, delta * 10.0)

# ==========================================
# FUNÇÕES DE DANO
# ==========================================

func tomar_dano(quantidade: int) -> void:
	# Se ele já está invulnerável, ignora o dano e sai da função
	if invulneravel:
		return
	# Deixa o Ogro invulnerável para evitar danos duplos no mesmo frame
	invulneravel = true 
	
	hp -= quantidade
	
	var flash_tween = create_tween()
	sprite.modulate = Color(10, 1, 1, 1)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
	
	if hp <= 0:
		morrer()
		
	# Espera o tempo de invulnerabilidade (0.2 a 0.3 segundos é o padrão de Action RPGs)
	await get_tree().create_timer(0.6).timeout
	invulneravel = false

func morrer():
	GameManager.ganhar_xp(xp_recompensa)
	GameManager.ganhar_gold(25) 
	queue_free()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("tomar_dano"):
		if not alvos_no_ataque.has(body):
			alvos_no_ataque.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if alvos_no_ataque.has(body):
		alvos_no_ataque.erase(body)

func verificar_impacto_ataque() -> void:
	for alvo in alvos_no_ataque:
		if is_instance_valid(alvo) and alvo.has_method("tomar_dano"):
			alvo.tomar_dano(attack_damage)

# ==========================================
# Lógica do Ataque do Ogro
# ==========================================

func executar_ataque() -> void:
	is_attacking = true
	can_attack = false
	anim_player.play("attack")
	
	await anim_player.animation_finished
	is_attacking = false
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# ==========================================
# Detecção de Visão (FOV)
# ==========================================

func _on_see_player_body_entered(body):
	if body == self: return
	if body.has_method("tomar_dano"):
		player = body
		is_chasing = true

func _on_see_player_body_exited(body):
	if body == player:
		player = null
		is_chasing = false
