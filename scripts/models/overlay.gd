extends Control
class_name Overlay

@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var _score: RichTextLabel = $StatBar/Stats/Score
@onready var _time: RichTextLabel = $StatBar/Stats/Time
@onready var _rings: RichTextLabel = $StatBar/Stats/Rings
@onready var _lives: Label = $StatBar/PlayerLives/PlayerLivesLabel/Lives
@onready var _game_over: HBoxContainer = $GameOver

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func set_score(score: int) -> void:
	score = clamp(score, 0, 999_999)
	_score.text = "[color=yellow]SCORE[/color] %6d" % [score]

func set_rings(amount: int, color: Color = Color.YELLOW) -> void:
	amount = clamp(amount, 0, 9_999)
	_rings.text = "[color=%s]RINGS[/color] %4d" % [color.to_html(), amount]
	queue_redraw()

func set_lives(amount: int) -> void:
	amount = clamp(amount, 0, 99)
	_lives.text = "×  %2d" % [amount]
	queue_redraw()

func set_time(t: float, color: Color = Color.YELLOW) -> void:
	var minutes: int = int(t) / 60
	var seconds: int = int(t) % 60
	_time.text = "[color=%s]TIME[/color] %01d:%02d" % [color.to_html(), minutes, seconds]
	queue_redraw()
