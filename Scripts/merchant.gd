extends Area2D

@export var dialog_box: Control 
@export var botao_conversar: Button 
@export var botao_loja: Button 

@export_category("Loja")
@export var loja_box: Control
@export var botao_sair_loja: Button
@export var botao_pocao: Button # Vamos ignorar por enquanto
# --- NOVOS BOTÕES DA LOJA ---
@export var botao_melhoria_vida: Button
@export var botao_melhoria_dano: Button
@export var botao_melhoria_mana: Button

@onready var texto_dialogo = $Control/DialogBox/dialogo

var player_in_range: bool = false
var vezes_conversadas: int = 0 
var player_node: Node2D = null # NOVO: Variável para guardar o Player!

func _ready():
	if botao_conversar:
		botao_conversar.pressed.connect(_on_botao_conversar_pressed)
	if botao_loja:
		botao_loja.pressed.connect(_on_botao_loja_pressed)
		
	# --- CONECTANDO OS BOTÕES DA LOJA ---
	if botao_sair_loja:
		botao_sair_loja.pressed.connect(_on_botao_sair_loja_pressed)
	if botao_pocao:
		botao_pocao.pressed.connect(_on_botao_pocao_pressed)
		
	if botao_melhoria_vida:
		botao_melhoria_vida.pressed.connect(_on_botao_melhoria_vida_pressed)
	if botao_melhoria_dano:
		botao_melhoria_dano.pressed.connect(_on_botao_melhoria_dano_pressed)
	if botao_melhoria_mana:
		botao_melhoria_mana.pressed.connect(_on_botao_melhoria_mana_pressed)
	
	# ==========================================
	# SINCRONIZAR TEXTOS DA LOJA COM AS VARIÁVEIS
	# ==========================================
	if botao_melhoria_vida:
		botao_melhoria_vida.text = "Vida++   %dg" % custo_vida
		
	if botao_melhoria_dano:
		botao_melhoria_dano.text = "Dano++   %dg" % custo_dano
		
	if botao_melhoria_mana:
		botao_melhoria_mana.text = "Mana++   %dg" % custo_mana

func _on_body_entered(body):
	if body.is_in_group("player"): 
		player_in_range = true
		player_node = body # Guarda o jogador na memória do mercador!

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null # Limpa a memória quando o jogador vai embora
		fechar_dialogo()

func _input(event):
	if event.is_action_pressed("interact") and player_in_range:
		if not dialog_box.visible and not loja_box.visible:
			abrir_dialogo()
		elif dialog_box.visible or loja_box.visible:
			fechar_dialogo()

# --- FUNÇÕES DE CONTROLE DA UI ---

func abrir_dialogo():
	dialog_box.show()
	texto_dialogo.text = "Hehe! O que vai querer hoje?"
	botao_conversar.show()
	botao_loja.show()
	get_tree().paused = true

func fechar_dialogo():
	dialog_box.hide()
	loja_box.hide() 
	get_tree().paused = false

# --- LÓGICA DE TRANSIÇÃO ---

func _on_botao_loja_pressed():
	dialog_box.hide()
	loja_box.show()

func _on_botao_sair_loja_pressed():
	loja_box.hide()
	abrir_dialogo()

@export_category("Valores da Loja")
@export_group("Custos (Gold)")
@export var custo_vida: int = 12
@export var custo_dano: int = 15
@export var custo_mana: int = 12

@export_group("Ganhos de Atributo")
@export var ganho_vida: int = 20
@export var ganho_mana: int = 20
# Novas variáveis em formato de porcentagem (0.25 = 25%, 0.15 = 15%)
@export var aumento_percentual_slash: float = 0.25 
@export var aumento_percentual_smite: float = 0.15



# ==========================================
# LÓGICA DE COMPRA DOS ITENS
# ==========================================

func tentar_comprar(valor: int) -> bool:
	if GameManager.gastar_gold(valor):
		return true
	else:
		print("Gold insuficiente!")
		return false

func _on_botao_melhoria_vida_pressed():
	if player_node and tentar_comprar(custo_vida):
		player_node.max_hp += ganho_vida
		player_node.current_hp = player_node.max_hp
		
		# Atualiza as barras
		player_node.hud_hp.max_value = player_node.max_hp
		player_node.hud_hp.value = player_node.current_hp
		
		# Força a atualização do texto do HUD mesmo com o jogo pausado!
		player_node.atualizar_textos_hud()
		print("Sua vida máxima aumentou!")

func _on_botao_melhoria_dano_pressed():
	if player_node and tentar_comprar(custo_dano):
		# Calcula quanto de dano extra o jogador vai ganhar
		var bonus_slash = round(player_node.dano_slash * aumento_percentual_slash)
		var bonus_smite = round(player_node.dano_poderoso * aumento_percentual_smite)
		
		# Aplica o bônus convertido para inteiro
		player_node.dano_slash += int(bonus_slash)
		player_node.dano_poderoso += int(bonus_smite)
		
		print("Slash subiu para: ", player_node.dano_slash)
		print("Smite subiu para: ", player_node.dano_poderoso)

func _on_botao_melhoria_mana_pressed():
	if player_node and tentar_comprar(custo_mana):
		player_node.max_mana += ganho_mana
		player_node.current_mana = player_node.max_mana
		
		# Atualiza as barras
		player_node.hud_mana.max_value = player_node.max_mana
		player_node.hud_mana.value = player_node.current_mana
		
		# Força a atualização do texto do HUD mesmo com o jogo pausado!
		player_node.atualizar_textos_hud()
		print("Sua mana máxima aumentou!")

func _on_botao_pocao_pressed():
	pass # Ignorado por enquanto

# --- FUNÇÕES DOS BOTÕES (Diálogo) ---

func _on_botao_conversar_pressed():
	vezes_conversadas += 1
	dialogos()

# --- FUNÇÃO DE DIÁLOGOS DINÂMICOS ---

func dialogos():
	match vezes_conversadas:
		1:
			texto_dialogo.text = "Sabe... essa floresta costumava ser mais segura."
		2:
			texto_dialogo.text = "Eu não sou apenas um mercador, eu já fui um mago respeitado! ...É sério."
		3:
			texto_dialogo.text = "Você faz muitas perguntas para quem não está comprando nada."
		4:
			texto_dialogo.text = "Vai comprar ou vai ficar aí me encarando?"
		_: 
			texto_dialogo.text = "..."
