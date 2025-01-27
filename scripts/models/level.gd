extends Node2D
class_name Level

@onready var camera: Camera2D = $SpawnPoint/Camera2D
@onready var player: Player = $SpawnPoint/Player
@onready var bg_music: AudioStreamPlayer = $BackgroundMusic

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
