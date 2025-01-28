extends Node

@onready var main_menu: Control = $MainMenu
@onready var level_manager: LevelManager = $LevelManager

var _game_ready: bool = false

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(main_menu.find_child("TitleScreen"), "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.25)
	tween.tween_property(main_menu.find_child("PressStart"), "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	tween.tween_callback(_toggle_game_ready)

func _process(_delta: float) -> void:
	if main_menu.visible and _game_ready:
		if Input.is_action_just_pressed("game_start"):
			main_menu.hide()
			level_manager.start_level(level_manager.default_level)

func _toggle_game_ready() -> void:
	_game_ready = not _game_ready
