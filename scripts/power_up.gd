extends Area3D

@export var rotate_speed: float = 2.0
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.15
@export var lifetime: float = 5.0
@export var blink_window: float = 1.5

var _t: float = 0.0
var _base_y: float = 0.0
var _life_left: float = 0.0

func _ready() -> void:
	_base_y = global_position.y
	_life_left = lifetime
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	rotate_y(rotate_speed * delta)
	global_position.y = _base_y + sin(_t * bob_speed) * bob_height

	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return
	if _life_left < blink_window:
		var freq := lerpf(3.0, 10.0, 1.0 - _life_left / blink_window)
		visible = int(_t * freq) % 2 == 0
	else:
		visible = true

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("apply_multi_shot"):
		body.apply_multi_shot()
	queue_free()
