extends Node

@onready var main_menu: Control = $MainMenu
@onready var level_manager: LevelManager = $LevelManager
@onready var menu_audio_player: AudioStreamPlayer = $MainMenu/AudioStreamPlayer

@onready var _title_screen: TextureRect = $MainMenu/TitleScreen
@onready var _press_start: Label = $MainMenu/PressStart

var _title_finished: bool = false

func _ready() -> void:
	_title_screen.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_press_start.modulate = Color(1.0, 1.0, 1.0, 0.0)
	show_main_menu()

func _process(_delta: float) -> void:
	if main_menu.visible and _title_finished:
		if Input.is_action_just_pressed("game_start"):
			hide_main_menu()
			level_manager.start_level()

func _toggle_title_finished() -> void:
	_title_finished = not _title_finished

func hide_main_menu() -> void:
	main_menu.hide()
	_title_screen.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_press_start.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_title_finished = false

func show_main_menu() -> void:
	var tween: Tween = create_tween()
	main_menu.show()
	menu_audio_player.play()
	tween.tween_property(_title_screen, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.25)
	tween.tween_property(_press_start, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0)
	tween.tween_callback(_toggle_title_finished)
