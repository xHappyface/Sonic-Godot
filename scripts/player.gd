extends CharacterBody2D
class_name Player

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

const _GRAVITY: float = (96.0 / 256.0) * 60.0
const _AIR_ACCELERATION: float = (24.0 / 256.0) * 60.0
const _AIR_DRAG: float = (8.0 / 256.0) * 60.0
const _TOP_Y_SPEED: float = 16.0 * 60.0
const _JUMP_FORCE: float = 6.5 * 60.0
const _ACCELERATION: float = (12.0 / 256.0) * 60.0
const _DECELERATION: float = 0.5 * 60.0
const _FRICTION: float = _ACCELERATION
const _TOP_SPEED: float = 6.0 * 60.0

var is_jumping: bool = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var move_direction: Vector2 = Input.get_vector("game_left", "game_right", "game_down", "game_up")
	if not is_on_floor():
		velocity.y = min((velocity.y + _GRAVITY), _TOP_Y_SPEED)
		if is_jumping and not Input.is_action_pressed("game_space"):
			if velocity.y < 0.0:
				velocity.y = max(velocity.y, -4.0 * 60.0)
		velocity.x = velocity.x + (move_direction.x * _AIR_ACCELERATION)
		if (velocity.y < 0.0) and (velocity.y > (-4.0 * 60.0)):
			velocity.x -= velocity.x * _AIR_DRAG * delta
	else:
		is_jumping = false
		if Input.is_action_just_pressed("game_space"):
			is_jumping = true
			velocity.y = max(velocity.y - _JUMP_FORCE, -_TOP_Y_SPEED)
		if move_direction.x == 0.0:
			if sign(velocity.x) > 0.0:
				velocity.x = max(velocity.x - _FRICTION, 0.0)
			else:
				velocity.x = min(velocity.x + _FRICTION, 0.0)
		else:
			if sign(move_direction.x) == sign(velocity.x) or sign(velocity.x) == 0.0:
				if move_direction.x > 0.0:
					velocity.x = min(velocity.x + _ACCELERATION, _TOP_SPEED)
				else:
					velocity.x = max(velocity.x - _ACCELERATION, -_TOP_SPEED)
			else:
				velocity.x -= sign(velocity.x) * _DECELERATION
	_handle_animations(move_direction)
	move_and_slide()

func _handle_animations(move_direction: Vector2) -> void:
	if (sign(move_direction.x) > 0.0 and sprite.flip_h) \
	  or (sign(move_direction.x) < 0.0 and not sprite.flip_h):
		sprite.flip_h = not sprite.flip_h
	if is_jumping:
		if anim_player.current_animation != "roll":
			anim_player.play("roll")
	else:
		if not is_on_floor() and velocity.y != 0.0:
			anim_player.play("fall")
		elif is_on_floor() and velocity.x != 0.0:
			if sign(move_direction.x) == sign(velocity.x) or move_direction.x == 0.0:
				anim_player.play("run0")
			else:
				anim_player.play("skid")
		elif is_on_floor() and move_direction.y != 0.0:
			if move_direction.y > 0.0:
				anim_player.play("look_up")
			else:
				anim_player.play("look_down")
		elif anim_player.current_animation != "idle":
			anim_player.play("idle")
