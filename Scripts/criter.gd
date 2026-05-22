extends Area2D

@export var speed: float = 100.0
@export var rotation_speed: float = 3.0 
@export var attack_range: float = 52.0 

# --- Variáveis para a Animação Procedural de Caminhada ---
@export var walk_anim_speed: float = 15.0 
@export var walk_anim_angle: float = 0.15 
@export var walk_anim_bounce: float = 5.0 
var walk_timer: float = 0.0
var sprite_base_position: Vector2 

# --- Variáveis de Ataque ---
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0 
var can_attack: bool = true
var is_attacking: bool = false # Nova variável para travar o monstro durante o ataque

var player: Node2D = null
var is_chasing: bool = false

@onready var sprite = $Sprite2D
@onready var vision_area = $FOV
@onready var anim_player = $AnimationPlayer 

func _ready():
	sprite_base_position = sprite.position
	vision_area.body_entered.connect(_on_see_player_body_entered)
	vision_area.body_exited.connect(_on_see_player_body_exited)

func _process(delta):
	vision_area.scale = Vector2.ONE 
	
	# Se estiver atacando, interrompe o resto do _process 
	# Isso garante que ele pare na frente do jogador e a animação não seja cortada
	if is_attacking:
		_reset_sprite_transform(delta)
		return
		
	if is_chasing and player:
		var direction = global_position.direction_to(player.global_position)
		vision_area.rotation = global_position.angle_to_point(player.global_position) + PI
		
		if direction.x != 0:
			sprite.flip_h = (direction.x > 0)
			
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > attack_range:
			# --- ESTADO: CAMINHANDO (Longe do Player) ---
			global_position += direction * speed * delta
			
			# Evita reiniciar a animação se ela já estiver tocando
			if anim_player.current_animation != "walking":
				anim_player.play("walking")
			
			walk_timer += delta
			sprite.rotation = sin(walk_timer * walk_anim_speed) * walk_anim_angle
			sprite.position.y = sprite_base_position.y - abs(cos(walk_timer * walk_anim_speed)) * walk_anim_bounce
			
		else:
			# --- ESTADO: PARADO PERTO DO PLAYER ---
			_reset_sprite_transform(delta)
			
			if can_attack:
				attack()
			else:
				# Se estiver muito perto mas em cooldown de ataque, fica em idle
				if anim_player.current_animation != "idle":
					anim_player.play("idle")
		
	else:
		# --- ESTADO: IDLE (Rodando FOV) ---
		vision_area.rotation += rotation_speed * delta
		var fov_direction = Vector2.LEFT.rotated(vision_area.rotation)
		sprite.flip_h = (fov_direction.x > 0)
		
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
			
		_reset_sprite_transform(delta)

func _reset_sprite_transform(delta):
	walk_timer = 0.0
	sprite.rotation = lerp(sprite.rotation, 0.0, delta * 10.0)
	sprite.position.y = lerp(sprite.position.y, sprite_base_position.y, delta * 10.0)

func _on_see_player_body_entered(body):
	if body == self: return
	if body.is_in_group("player") or body.name == "player":
		player = body
		is_chasing = true

func _on_see_player_body_exited(body):
	if body == player:
		player = null
		is_chasing = false
		
func attack():
	if can_attack:
		can_attack = false 
		is_attacking = true # Trava o monstro no frame atual
		
		anim_player.play("attack")
		print("Ogre atacou o jogador!")
		
		# Aguarda o AnimationPlayer terminar exatamente a animação atual ("attack")
		await anim_player.animation_finished
		
		# Libera o monstro para andar e trocar de animação novamente
		is_attacking = false 
		
		# Inicia o tempo de recarga até poder atacar novamente
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
