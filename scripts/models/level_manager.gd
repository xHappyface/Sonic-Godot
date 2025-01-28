extends Node
class_name LevelManager

@onready var default_level: PackedScene = preload("res://scenes/level_0.tscn")

@onready var _time: Timer = $Time
@onready var _overlay: Overlay = $Overlay
@onready var _game_view: SubViewport = $GameViewport/GameView

var _level: Level = null
var _player: Player = null

const _STARTING_RINGS: int = 0
const _STARTING_LIVES: int = 3

var _is_level_running: bool = false

var score: int = 0
var rings: int = _STARTING_RINGS
var lives: int = _STARTING_LIVES

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not _is_level_running:
		return
	_overlay.set_time(_time.wait_time - _time.time_left)

func start_level(packed_level: PackedScene = default_level) -> void:
	if (not packed_level.can_instantiate()):
		return
	if not _level:
		_level = packed_level.instantiate()
	_game_view.add_child(_level)
	_player = _level.player
	_overlay.reparent(_level.camera)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.set_score(score)
	_overlay.set_time(_time.wait_time - _time.time_left)
	_overlay.set_rings(rings)
	_overlay.set_lives(lives)
	_player.game_over.connect(_on_game_over)
	_overlay.show()
	_game_view.get_parent().show()
	_time.start(600.0)
	_is_level_running = true

func _on_game_over() -> void:
	print("GAME OVER")
	_player.active = false
	_is_level_running = false
	_time.stop()
	_level.bg_music.stop()
	_overlay.anim_player.play("game_over")
	var tween: Tween = create_tween()
	tween.tween_callback(get_parent().show_main_menu).set_delay(3.0)
	tween.tween_callback(_game_view.get_parent().hide)
	tween.tween_callback(_overlay.hide)
	tween.tween_callback(_free_level)

func _free_level() -> void:
	if not _level:
		return
	_overlay.reparent(self)
	_overlay.anim_player.play("RESET")
	_level.queue_free()
	_level = null
