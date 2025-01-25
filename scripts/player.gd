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
const _PATIENCE: float = 3.5

var idling: float = 0.0
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
		if velocity.y == clamp(velocity.y, -4.0 * 60, 0.0):
			velocity.x -= move_direction.x * _AIR_DRAG * delta
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
				velocity.x = clamp(velocity.x + (move_direction.x * _ACCELERATION), -_TOP_SPEED, _TOP_SPEED)
			else:
				velocity.x -= sign(velocity.x) * _DECELERATION
	_handle_animations(move_direction, delta)
	move_and_slide()
	if is_on_floor():
		rotation = get_floor_normal().angle() + deg_to_rad(90)

func _handle_animations(move_direction: Vector2, delta: float) -> void:
	var temp_idling: float = min(idling + delta, _PATIENCE)
	idling = 0.0
	if (sign(move_direction.x) > 0.0 and sprite.flip_h) \
	  or (sign(move_direction.x) < 0.0 and not sprite.flip_h):
		sprite.flip_h = not sprite.flip_h
	if is_jumping:
		if anim_player.current_animation != "roll0" and abs(velocity.x) < _TOP_SPEED:
			anim_player.play("roll0")
		elif anim_player.current_animation != "roll1" and abs(velocity.x) >= _TOP_SPEED:
			anim_player.play("roll1")
	else:
		if not is_on_floor() and velocity.y >= _TOP_Y_SPEED / 2.0:
			if not anim_player.current_animation == "fall":
				anim_player.play("fall")
		elif not is_on_floor() and velocity.y < _TOP_Y_SPEED / 2.0:
			if velocity.x == 0.0 and not anim_player.current_animation == "idle":
				anim_player.play("idle")
			elif velocity.x != 0.0:
				if abs(velocity.x) >= _TOP_SPEED * 0.67:
					anim_player.play("run0_1")
				else:
					anim_player.play("run0")
		elif is_on_floor() and velocity.x != 0.0:
			if is_on_floor() and is_on_wall() and move_direction.x != 0.0:
				if not anim_player.current_animation == "push_r" and not sprite.flip_h:
					anim_player.play("push_r")
				elif not anim_player.current_animation == "push_l" and sprite.flip_h:
					anim_player.play("push_l")
			elif sign(move_direction.x) == sign(velocity.x) or move_direction.x == 0.0:
				if abs(velocity.x) >= _TOP_SPEED:
					anim_player.play("run1")
				elif abs(velocity.x) >= _TOP_SPEED * 0.67:
					if anim_player.current_animation == "run0":
						var frame: int = sprite.frame + 1
						anim_player.play("run0_1")
						anim_player.seek((frame - 12) * 0.05)
					else:
						anim_player.play("run0_1")
				else:
					anim_player.play("run0")
			else:
				anim_player.play("brake")
		elif is_on_floor() and move_direction.y != 0.0:
			if move_direction.y > 0.0:
				anim_player.play("look_up")
			else:
				anim_player.play("look_down")
		elif anim_player.current_animation != "idle" and temp_idling < _PATIENCE:
			idling = temp_idling
			anim_player.play("idle")
		else:
			idling = temp_idling
			if idling >= _PATIENCE:
				anim_player.play("bored")
