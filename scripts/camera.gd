extends Camera2D

@onready var _player: Player = $"../Player"

const _SPEED: float = 16.0

var _follow_area: Rect2 = Rect2()

func _ready() -> void:
	_follow_area = get_child(0).shape.get_rect()

func _physics_process(_delta: float) -> void:
	var player_position: Vector2 = _player.game_origin.global_position
	if player_position.y > global_position.y + (_follow_area.size.y / 2.0):
		global_position.y = move_toward(global_position.y, player_position.y, _SPEED)
	elif player_position.y < global_position.y - (_follow_area.size.y / 2.0):
		global_position.y = move_toward(global_position.y, player_position.y + (_follow_area.size.y / 2.0), _SPEED)
	if player_position.x > global_position.x + (_follow_area.size.x / 2.0):
		global_position.x = move_toward(global_position.x, player_position.x - (_follow_area.size.x / 2.0), _SPEED)
	elif player_position.x < global_position.x - (_follow_area.size.x / 2.0):
		global_position.x = move_toward(global_position.x, player_position.x + (_follow_area.size.x / 2.0), _SPEED)
