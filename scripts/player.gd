extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 8.0
@export var gravity: float = 20.0
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.15
@export var max_health: int = 3
@export var arena_bounds: float = 19.0

@export var shoot_sound: AudioStream
@export_range(-40.0, 10.0, 0.5) var shoot_volume_db: float = 0.0

@export var multi_shot_count: int = 4
@export var multi_shot_spread_deg: float = 30.0
@export var multi_shot_duration: float = 15.0

@export var idle_anim: String = "Rig_Medium_MovementBasic/Jump_Idle"
@export var run_anim: String = "Rig_Medium_MovementBasic/Running_A"

@onready var _muzzle: Marker3D = $Muzzle
@onready var _anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)

var _fire_cooldown: float = 0.0
var _health: int
var _current_anim: String = ""
var _multi_shot_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_health = max_health
	health_changed.emit(_health, max_health)
	_setup_anim_loops()
	_set_anim(idle_anim)

func _setup_anim_loops() -> void:
	if _anim_player == null:
		return
	for name in [idle_anim, run_anim]:
		if _anim_player.has_animation(name):
			var a := _anim_player.get_animation(name)
			if a != null:
				a.loop_mode = Animation.LOOP_LINEAR

func _set_anim(name: String) -> void:
	if _anim_player == null or _current_anim == name:
		return
	if not _anim_player.has_animation(name):
		return
	_anim_player.play(name)
	_current_anim = name

func take_damage(amount: int) -> void:
	_health = max(0, _health - amount)
	health_changed.emit(_health, max_health)
	if _health == 0:
		died.emit()
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	if _multi_shot_timer > 0.0:
		_multi_shot_timer = maxf(0.0, _multi_shot_timer - delta)
	_handle_movement(delta)
	_handle_aim()
	_handle_shoot(delta)
	_clamp_to_arena()

func apply_multi_shot() -> void:
	_multi_shot_timer += multi_shot_duration

func is_multi_shot_active() -> bool:
	return _multi_shot_timer > 0.0

func get_multi_shot_remaining() -> float:
	return _multi_shot_timer

func get_health() -> int:
	return _health

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -arena_bounds, arena_bounds)
	global_position.z = clampf(global_position.z, -arena_bounds, arena_bounds)
	if global_position.y < -1.0:
		global_position.y = 0.5
		velocity = Vector3.ZERO

func _handle_movement(delta: float) -> void:
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.z = Input.get_axis("move_up", "move_down")

	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if input_dir.length() > 0.1:
		_set_anim(run_anim)
	else:
		_set_anim(idle_anim)

func _get_aim_point() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return global_position - global_basis.z * 5.0

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)

	if absf(ray_dir.y) < 0.001:
		return global_position - global_basis.z * 5.0

	var t := (global_position.y - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return global_position - global_basis.z * 5.0

	var target := ray_origin + ray_dir * t
	target.y = global_position.y
	return target

func _handle_aim() -> void:
	var target := _get_aim_point()
	if global_position.distance_to(target) > 0.1:
		look_at(target, Vector3.UP)

func _handle_shoot(delta: float) -> void:
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return
	if not Input.is_action_pressed("shoot"):
		return
	if bullet_scene == null:
		return

	var target := _get_aim_point()
	target.y = _muzzle.global_position.y
	var direction := target - _muzzle.global_position
	if direction.length_squared() < 0.001:
		direction = -global_basis.z
	direction = direction.normalized()

	for d in _shot_directions(direction):
		var bullet: Area3D = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = _muzzle.global_position
		if bullet.has_method("launch"):
			bullet.launch(d)
	_play_shoot_sound()
	_fire_cooldown = fire_rate

func _shot_directions(forward: Vector3) -> Array[Vector3]:
	var dirs: Array[Vector3] = []
	if not is_multi_shot_active() or multi_shot_count <= 1:
		dirs.append(forward)
		return dirs
	var spread := deg_to_rad(multi_shot_spread_deg)
	var step := spread / float(multi_shot_count - 1)
	var start := -spread * 0.5
	for i in multi_shot_count:
		dirs.append(forward.rotated(Vector3.UP, start + step * i))
	return dirs

func _play_shoot_sound() -> void:
	if shoot_sound == null:
		return
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = shoot_sound
	sfx.volume_db = shoot_volume_db
	sfx.global_position = _muzzle.global_position
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
