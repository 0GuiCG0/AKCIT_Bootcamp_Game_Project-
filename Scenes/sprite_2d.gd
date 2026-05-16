extends Sprite2D

var coordFrameX: int = 0 # (0, 1) = Idle animation
var coordFrameY: int = 1 # (0, 2) = Moving animation
var flowTime: float = 0.0
var changer: int = 0

func _ready() -> void:
	position = Vector2(550, 320)


func _process(delta: float) -> void:
	flowTime += delta
