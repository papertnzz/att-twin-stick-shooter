extends Node

signal wave_started(wave: int, enemy_count: int)
signal wave_cleared(wave: int)
signal kills_changed(total_kills: int)

@export var enemy_scene: PackedScene
@export var warrior_scene: PackedScene
@export var warrior_min_wave: int = 2
@export var mage_scene: PackedScene
@export var mage_min_wave: int = 3
@export var mixed_min_wave: int = 4
@export var spawn_points_parent: NodePath
@export var spawn_radius: float = 12.0
@export var wave_delay: float = 3.0
@export var enemies_per_wave_base: int = 3
@export var enemies_per_wave_increment: int = 2
@export var spawn_interval: float = 0.8

var _wave: int = 0
var _enemies_alive: int = 0
var _kills: int = 0
var _spawn_points: Array[Node3D] = []
var _spawning: bool = false
var _wave_clear_pending: bool = false

func _ready() -> void:
	_collect_spawn_points()
	await get_tree().create_timer(1.0).timeout
	_start_next_wave()

func _collect_spawn_points() -> void:
	if spawn_points_parent.is_empty():
		return
	var parent := get_node_or_null(spawn_points_parent)
	if parent == null:
		return
	for child in parent.get_children():
		if child is Node3D:
			_spawn_points.append(child)

func _start_next_wave() -> void:
	_wave += 1
	var count := enemies_per_wave_base + (_wave - 1) * enemies_per_wave_increment
	wave_started.emit(_wave, count)
	_spawn_wave(count)

func _spawn_wave(count: int) -> void:
	_spawning = true
	var queue: Array[Node3D] = []
	for i in count:
		if _spawn_points.size() > 0 and queue.is_empty():
			queue = _spawn_points.duplicate()
			queue.shuffle()
		var sp: Node3D = queue.pop_back() if not queue.is_empty() else null
		_spawn_one(sp)
		if i < count - 1:
			await get_tree().create_timer(spawn_interval).timeout
	_spawning = false
	_check_wave_clear()

func _spawn_one(spawn_point: Node3D) -> void:
	var scene := _pick_enemy_scene()
	if scene == null:
		push_warning("WaveSpawner: enemy_scene not set")
		return

	var enemy: Node3D = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	if spawn_point != null:
		enemy.global_position = spawn_point.global_position
	else:
		var angle := randf() * TAU
		enemy.position = Vector3(cos(angle) * spawn_radius, 0.0, sin(angle) * spawn_radius)
	_enemies_alive += 1

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	_enemies_alive -= 1
	_kills += 1
	kills_changed.emit(_kills)
	_check_wave_clear()

func _pick_enemy_scene() -> PackedScene:
	var available: Array[PackedScene] = []
	if mage_scene != null and _wave >= mage_min_wave:
		available.append(mage_scene)
	if warrior_scene != null and _wave >= warrior_min_wave:
		available.append(warrior_scene)
	if enemy_scene != null:
		available.append(enemy_scene)
	if available.is_empty():
		return enemy_scene
	if _wave >= mixed_min_wave:
		return available[randi() % available.size()]
	return available[0]

func _check_wave_clear() -> void:
	if _spawning:
		return
	if _enemies_alive > 0:
		return
	if _wave_clear_pending:
		return
	_wave_clear_pending = true
	wave_cleared.emit(_wave)
	await get_tree().create_timer(wave_delay).timeout
	_wave_clear_pending = false
	_start_next_wave()
