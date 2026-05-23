extends CharacterBody3D

signal died

@export var speed: float = 7.0
@export var max_health: int = 3
@export var gravity: float = 20.0
@export var touch_damage: int = 1
@export var touch_cooldown: float = 0.8
@export var melee_range: float = 1.5
@export var attack_windup: float = 0.4
@export var attack_swing_arc_deg: float = 80.0
@export var attack_thrust: float = 0.7
@export var idle_swing_arc_deg: float = 20.0
@export var idle_swing_speed: float = 5.0
@export var run_anim: String = "Rig_Medium_MovementBasic/Running_A"
@export var death_sound: AudioStream
@export_range(-40.0, 10.0, 0.5) var death_volume_db: float = 0.0
@export_range(0.0, 1.0, 0.05) var power_up_drop_chance: float = 0.15
@export var shield_hp: int = 0

const POWER_UP_SCENE := preload("res://scenes/power_up.tscn")

var _health: int
var _touch_timer: float = 0.0
var _dying: bool = false
var _attacking: bool = false
var _attack_phase: float = 0.0
var _attack_dealt: bool = false
var _sword_base_pos: Vector3 = Vector3.ZERO
var _t: float = 0.0
var _shield_hp: int = 0
@onready var _anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var _sword: Node3D = get_node_or_null("Sword")
@onready var _shield: Node3D = get_node_or_null("Shield")

func _ready() -> void:
	_health = max_health
	_shield_hp = shield_hp
	add_to_group("enemies")
	_start_animation()
	_update_shield_visual()
	if _sword != null:
		_sword_base_pos = _sword.position

func _update_shield_visual() -> void:
	if _shield == null:
		return
	_shield.visible = _shield_hp > 0

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
	_t += delta
	_touch_timer -= delta
	var player := _find_player()

	if _attacking:
		_process_attack(delta, player)
		_apply_gravity(delta)
		move_and_slide()
		return

	_apply_idle_swing()

	if player != null:
		var to_player := player.global_position - global_position
		to_player.y = 0.0
		var dist := to_player.length()

		if dist > 0.01:
			var dir := to_player.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			look_at(global_position + dir, Vector3.UP)

		if dist < melee_range and _touch_timer <= 0.0:
			if _sword != null:
				_start_attack()
			else:
				if player.has_method("take_damage"):
					player.take_damage(touch_damage)
					_touch_timer = touch_cooldown

	_apply_gravity(delta)
	move_and_slide()

func _start_attack() -> void:
	_attacking = true
	_attack_phase = 0.0
	_attack_dealt = false
	velocity.x = 0.0
	velocity.z = 0.0

func _apply_idle_swing() -> void:
	if _sword == null:
		return
	var arc := deg_to_rad(idle_swing_arc_deg)
	_sword.rotation.x = sin(_t * idle_swing_speed) * arc
	_sword.position = _sword_base_pos

func _process_attack(delta: float, player: Node3D) -> void:
	_attack_phase += delta / attack_windup
	if _sword != null:
		var s := sin(_attack_phase * PI)
		var arc := deg_to_rad(attack_swing_arc_deg)
		_sword.rotation.x = -s * arc
		_sword.position.z = _sword_base_pos.z - s * attack_thrust
	if not _attack_dealt and _attack_phase >= 0.5:
		_attack_dealt = true
		if player != null:
			var to_player := player.global_position - global_position
			to_player.y = 0.0
			if to_player.length() < melee_range + 0.5 and player.has_method("take_damage"):
				player.take_damage(touch_damage)
	if _attack_phase >= 1.0:
		_attacking = false
		_touch_timer = touch_cooldown
		if _sword != null:
			_sword.rotation.x = 0.0
			_sword.position = _sword_base_pos

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func take_damage(amount: int) -> void:
	if _dying:
		return
	if _shield_hp > 0:
		_shield_hp = max(0, _shield_hp - amount)
		if _shield_hp == 0:
			_update_shield_visual()
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
