extends CanvasLayer

@onready var _wave_label: Label = $WaveLabel
@onready var _kills_label: Label = $KillsLabel
@onready var _center_label: Label = $CenterLabel
@onready var _power_up_label: Label = $PowerUpLabel
@onready var _hearts_container: HBoxContainer = $HeartsContainer
@onready var _game_over_menu: Control = $GameOverMenu
@onready var _restart_button: Button = $GameOverMenu/Center/VBox/RestartButton
@onready var _quit_button: Button = $GameOverMenu/Center/VBox/QuitButton

var _game_over: bool = false
var _player: Node = null
var _hearts: Array[Control] = []

func _ready() -> void:
	_center_label.text = ""
	_wave_label.text = "Wave: 0"
	_kills_label.text = "Kills: 0"

	for child in _hearts_container.get_children():
		if child is Control:
			_hearts.append(child)

	_restart_button.pressed.connect(_on_restart)
	_quit_button.pressed.connect(_on_quit)

	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p: Node = players[0]
		_player = p
		if p.has_signal("health_changed"):
			p.health_changed.connect(_on_health_changed)
		if p.has_signal("died"):
			p.died.connect(_on_player_died)
		if p.has_method("get_health") and "max_health" in p:
			_on_health_changed(p.get_health(), p.max_health)

	var spawner := get_tree().current_scene.get_node_or_null("WaveSpawner")
	if spawner:
		if spawner.has_signal("wave_started"):
			spawner.wave_started.connect(_on_wave_started)
		if spawner.has_signal("kills_changed"):
			spawner.kills_changed.connect(_on_kills_changed)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_power_up_label.text = ""
		return
	if _player.has_method("is_multi_shot_active") and _player.is_multi_shot_active():
		var remaining: float = _player.get_multi_shot_remaining()
		_power_up_label.text = "Multi-Shot: %ds" % int(ceil(remaining))
	else:
		_power_up_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		_toggle_fullscreen()
		return
	if not _game_over:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_health_changed(current: int, maximum: int) -> void:
	for i in _hearts.size():
		_hearts[i].visible = i < maximum
		if i < current:
			_hearts[i].modulate = Color(1, 1, 1, 1)
		else:
			_hearts[i].modulate = Color(0.25, 0.25, 0.25, 0.4)

func _on_wave_started(wave: int, enemy_count: int) -> void:
	_wave_label.text = "Wave: %d" % wave
	_show_announcement("WAVE %d" % wave, 2.0)

func _on_kills_changed(total_kills: int) -> void:
	_kills_label.text = "Kills: %d" % total_kills

func _on_player_died() -> void:
	_game_over = true
	_center_label.text = ""
	_game_over_menu.visible = true
	_restart_button.grab_focus()

func _on_restart() -> void:
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()

func _show_announcement(text: String, duration: float) -> void:
	if _game_over:
		return
	_center_label.text = text
	await get_tree().create_timer(duration).timeout
	if not _game_over and _center_label.text == text:
		_center_label.text = ""
