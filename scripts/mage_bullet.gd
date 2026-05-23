extends Area3D

@export var speed: float = 8.0
@export var lifetime: float = 3.0
@export var damage: int = 1

var _velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(direction: Vector3) -> void:
	_velocity = direction.normalized() * speed
	look_at(global_position + _velocity, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
