extends Node

@onready var _default_level: PackedScene = preload("res://scenes/level_0.tscn")

@onready var _time: Timer = $Time
@onready var _overlay: Overlay = $Overlay

var _level: Level = null
var _player: Player = null

const STARTING_LIVES: int = 3

var _game_over: bool = false
var lives: int = STARTING_LIVES

func _ready() -> void:
	_level = _default_level.instantiate()
	add_child(_level)
	_player = _level.player
	_overlay.reparent(_level.camera)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.set_score(0)
	_overlay.set_time(_time.wait_time - _time.time_left)
	_overlay.set_rings(0)
	_overlay.set_lives(lives)
	_time.start()

func _process(_delta: float) -> void:
	if (not _level) or (not _player):
		return
	if (not _game_over) and _player.game_over:
		_game_over = true
		_level.bg_music.stop()
		_overlay.anim_player.play("game_over")
		return
	elif not _game_over:
		_overlay.set_time(_time.wait_time - _time.time_left)
