extends Area3D

@export var speed: float = 10.0
@export var lifetime: float = 2.0
@export var damage: int = 1
@export var hit_sound: AudioStream
@export_range(-40.0, 10.0, 0.5) var hit_volume_db: float = 0.0

var _velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(direction: Vector3) -> void:
	_velocity = direction.normalized() * speed
	look_at(global_position + _velocity, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_play_hit_sound()
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player"):
		return
	if area.has_method("take_damage"):
		area.take_damage(damage)
		_play_hit_sound()
		queue_free()

func _play_hit_sound() -> void:
	if hit_sound == null:
		return
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = hit_sound
	sfx.volume_db = hit_volume_db
	sfx.global_position = global_position
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
