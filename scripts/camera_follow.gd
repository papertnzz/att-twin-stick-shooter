extends Camera3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0.0, 12.0, 8.0)
@export var smooth_speed: float = 5.0

var _target: Node3D

func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, clampf(smooth_speed * delta, 0.0, 1.0))
