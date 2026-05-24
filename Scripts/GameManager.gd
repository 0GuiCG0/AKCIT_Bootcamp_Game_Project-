extends Node

signal gold_alterado(novo_total)
signal xp_alterada(nova_xp) # NOVO: Sinal para avisar que a XP mudou

var gold: int = 0
var xp: float = 0 # NOVO: Armazena a XP globalmente

func ganhar_gold(quantidade: int) -> void:
	gold += quantidade
	gold_alterado.emit(gold)

func gastar_gold(quantidade: int) -> bool:
	if gold >= quantidade:
		gold -= quantidade
		gold_alterado.emit(gold)
		return true
	return false

# NOVA FUNÇÃO: Centraliza o ganho de experiência do jogo
func ganhar_xp(quantidade: int) -> void:
	xp += quantidade
	xp_alterada.emit(xp) # Avisa o player/HUD que a XP subiu
