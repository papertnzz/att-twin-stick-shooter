extends CharacterBody3D

signal died

@export var speed: float = 2.5
@export var max_health: int = 4
@export var gravity: float = 20.0
@export var ideal_distance: float = 8.0
@export var fire_rate: float = 1.5
@export var fire_range: float = 16.0
@export var bullet_scene: PackedScene
@export var run_anim: String = "Rig_Medium_MovementBasic/Running_A"
@export var death_sound: AudioStream
@export_range(-40.0, 10.0, 0.5) var death_volume_db: float = 0.0
@export_range(0.0, 1.0, 0.05) var power_up_drop_chance: float = 0.20

const POWER_UP_SCENE := preload("res://scenes/power_up.tscn")

@onready var _muzzle: Marker3D = $Muzzle
@onready var _anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)

var _health: int
var _fire_timer: float = 0.0
var _dying: bool = false

func _ready() -> void:
	_health = max_health
	add_to_group("enemies")
	_start_animation()

func _start_animation() -> void:
	if _anim_player == null:
		return
	if not _anim_player.has_animation(run_anim):
		return
	var anim := _anim_player.get_animation(run_anim)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	_anim_player.play(run_anim)

func _physics_process(delta: float) -> void:
	_fire_timer -= delta

	var player := _find_player()
	if player != null:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		var dist := to_player.length()

		if dist > 0.01:
			var dir := to_player.normalized()
			look_at(global_position + dir, Vector3.UP)

			if dist > ideal_distance + 0.5:
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
			elif dist < ideal_distance - 1.0:
				velocity.x = -dir.x * speed
				velocity.z = -dir.z * speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0

			if _fire_timer <= 0.0 and dist < fire_range:
				_shoot(dir)
				_fire_timer = fire_rate

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _shoot(direction: Vector3) -> void:
	if bullet_scene == null or _muzzle == null:
		return
	var bullet: Area3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = _muzzle.global_position
	if bullet.has_method("launch"):
		bullet.launch(direction)

func take_damage(amount: int) -> void:
	if _dying:
		return
	_health -= amount
	if _health <= 0:
		_dying = true
		died.emit()
		_play_death_sound()
		_maybe_drop_power_up()
		queue_free()

func _maybe_drop_power_up() -> void:
	if randf() > power_up_drop_chance:
		return
	var pu: Node3D = POWER_UP_SCENE.instantiate()
	get_tree().current_scene.add_child(pu)
	pu.global_position = global_position

func _play_death_sound() -> void:
	if death_sound == null:
		return
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = death_sound
	sfx.volume_db = death_volume_db
	sfx.global_position = global_position
	get_tree().current_scene.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0] as Node3D
	return null
