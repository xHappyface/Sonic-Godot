extends CharacterBody2D
class_name Player

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var _sfx_jump: AudioStreamWAV = preload("res://assets/sounds/sound effects/Sonic_CD_Jump.wav")
@onready var _sfx_brake: AudioStreamWAV = preload("res://assets/sounds/sound effects/Sonic_CD_Brake.wav")
@onready var _sfx_charge: AudioStreamWAV = preload("res://assets/sounds/sound effects/Sonic_CD_Charge.wav")
@onready var _sfx_release: AudioStreamWAV = preload("res://assets/sounds/sound effects/Sonic_CD_Release.wav")
@onready var _sfx_outta_here: AudioStreamWAV = preload("res://assets/sounds/sound effects/Sonic_Outta_Here.wav")

const _GRAVITY: float = (96.0 / 256.0) * 60.0
const _AIR_ACCELERATION: float = (24.0 / 256.0) * 60.0
const _AIR_DRAG: float = (8.0 / 256.0) * 60.0
const _TOP_Y_SPEED: float = 16.0 * 60.0
const _JUMP_FORCE: float = 6.5 * 60.0
const _ACCELERATION: float = (15.0 / 256.0) * 60.0
const _DECELERATION: float = 0.5 * 60.0
const _FRICTION: float = _ACCELERATION
const _TOP_SPEED: float = 6.0 * 60.0
const _PATIENCE: float = 3.0
const _ROLL_FRICTION: float = _ACCELERATION / 2.0
const _ROLL_DECELERATION: float = (32.0 / 256.0) * 60.0

var _control_lock: float = 0.0
var _idling: float = 0.0
var _is_jumping: bool = false
var _spinrev: float = 0.0
var _audio_buffer: float = 0.0
var _is_spinning_out: bool = false

var active: bool = true
var game_over: bool = false
var peeling_out: float = 0.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if (not active) or game_over:
		return
	if _idling >= _PATIENCE * 60.0:
		active = false
		game_over = true
		anim_player.play("outta_here")
		audio_player.stream = _sfx_outta_here
		audio_player.play()
		return
	_control_lock = max(_control_lock - delta, 0.0)
	var action_pressed: bool = Input.is_action_just_pressed("game_action")
	var move_direction: Vector2 = Input.get_vector("game_left", "game_right", "game_down", "game_up")
	var real_input: Vector2 = move_direction
	var temp_spinrev: float = _spinrev
	_spinrev = 0.0
	_audio_buffer = max(_audio_buffer - delta, 0.0)
	temp_spinrev = clamp(temp_spinrev - ((8.0 / 256.0) * delta), 0.0, 8.0)
	if _control_lock > 0.0:
		move_direction.x = 0.0
	if move_direction.x != 0.0:
		move_direction.y = 0.0
	if not is_on_floor():
		velocity.y = min((velocity.y + _GRAVITY), _TOP_Y_SPEED)
		if _is_jumping and not action_pressed:
			if velocity.y < 0.0:
				velocity.y = max(velocity.y, -4.0 * 60.0)
		velocity.x = velocity.x + (move_direction.x * _AIR_ACCELERATION)
		if velocity.y == clamp(velocity.y, -4.0 * 60, 0.0):
			velocity.x -= move_direction.x * _AIR_DRAG * delta
	else:
		_is_jumping = false
		if _is_spinning_out and (abs(velocity.x) <= 3.0 * 60.0 or move_direction.y > 0.0):
			_is_spinning_out = false
		if velocity.x == 0.0 and move_direction.y < 0.0:
			_spinrev = temp_spinrev
		if temp_spinrev > 0.0 and move_direction.y >= 0.0:
			var launch_speed = 8.0 + (_spinrev / 2.0)
			if not sprite.flip_h:
				velocity.x = launch_speed * 60.0
			else:
				velocity.x = -launch_speed * 60.0
			_is_spinning_out = true
			_spinrev = 0.0
			if audio_player.stream != _sfx_release:
				audio_player.stream = _sfx_release
			audio_player.play()
		elif (action_pressed and real_input.y >= 0.0 and velocity.x == 0.0) or \
		  (action_pressed and velocity.x != 0.0):
			_is_jumping = true
			velocity.y = max(velocity.y - _JUMP_FORCE, -_TOP_Y_SPEED)
			if audio_player.stream != _sfx_jump:
				audio_player.set_stream(_sfx_jump)
			audio_player.play()
		if action_pressed and velocity.x == 0.0 and move_direction.y < 0.0:
			_spinrev = min(temp_spinrev + 2.0, 8.0)
			print(_spinrev)
			if audio_player.stream != _sfx_charge:
				audio_player.set_stream(_sfx_charge)
			if _audio_buffer <= 0.0 or not audio_player.playing:
				_audio_buffer = 0.178
				audio_player.play()
		elif real_input.x == 0.0:
			if sign(velocity.x) > 0.0:
				velocity.x = max(velocity.x - _FRICTION, 0.0)
			else:
				velocity.x = min(velocity.x + _FRICTION, 0.0)
		else:
			if move_direction.y < 0.0:
				if velocity.x > 0.0 and sign(real_input.x) != sign(velocity.x):
					velocity.x = max(velocity.x - _ROLL_DECELERATION, 0.0)
				elif velocity.x < 0.0 and sign(real_input.x) != sign(velocity.x):
					velocity.x = min(velocity.x + _ROLL_DECELERATION, 0.0)
				elif velocity.x > 0.0:
					velocity.x = max(velocity.x - _ROLL_FRICTION, 0.0)
				elif velocity.x < 0.0:
					velocity.x = min(velocity.x + _ROLL_FRICTION, 0.0)
			elif sign(move_direction.x) == sign(velocity.x) or sign(velocity.x) == 0.0:
				velocity.x = clamp(velocity.x + (move_direction.x * _ACCELERATION), -_TOP_SPEED, _TOP_SPEED)
			else:
				var original_sign: float = sign(velocity.x)
				velocity.x -= original_sign * _DECELERATION
				if sign(velocity.x) != original_sign:
					velocity.x = -original_sign * 0.5
				if abs(velocity.x) > 2.0 * 60.0:
					if audio_player.stream != _sfx_brake:
						audio_player.set_stream(_sfx_brake)
					if not audio_player.playing:
						audio_player.play()
	_handle_animations(delta, move_direction)
	move_and_slide()
	if is_on_floor():
		var angle: float = get_floor_normal().angle() + deg_to_rad(90)
		rotation = round(angle / (PI / 4.0)) * (PI / 4.0)

func _handle_animations(delta: float, move_direction: Vector2) -> void:
	var temp_idling: float = min(_idling + delta, _PATIENCE * 60.0)
	_idling = 0.0
	if (sign(move_direction.x) > 0.0 and sprite.flip_h) \
	  or (sign(move_direction.x) < 0.0 and not sprite.flip_h):
		sprite.flip_h = not sprite.flip_h
	if _is_jumping or _is_spinning_out:
		_play_roll_animation()
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
			elif velocity.x != 0.0 and move_direction.y < 0.0:
				_play_roll_animation()
			elif velocity.x != 0.0 and (sign(move_direction.x) == sign(velocity.x) or move_direction.x == 0.0):
				if sign(velocity.x) > 0.0:
					sprite.flip_h = false
				else:
					sprite.flip_h = true
				if (abs(velocity.x) > _TOP_SPEED or peeling_out >= 0.1) and \
				  anim_player.current_animation != "run2":
					anim_player.play("run2")
				elif abs(velocity.x) >= _TOP_SPEED and \
				  (anim_player.current_animation != "run1" or anim_player.current_animation != "run2"):
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
			elif abs(velocity.x) > 2.0 * 60.0 and \
			  (anim_player.current_animation != "roll0" or anim_player.current_animation != "roll1"):
				anim_player.play("brake")
		elif is_on_floor() and move_direction.y != 0.0:
			if move_direction.y > 0.0:
				if anim_player.current_animation != "look_up":
					anim_player.play("look_up")
			elif _spinrev > 0.0:
				if _spinrev >= 6.0:
					if anim_player.current_animation != "roll1":
						anim_player.play("roll1")
				elif anim_player.current_animation != "roll0":
					anim_player.play("roll0")
			elif anim_player.current_animation != "look_down":
				anim_player.play("look_down")
		elif anim_player.current_animation != "idle" and temp_idling < _PATIENCE:
			_idling = temp_idling
			anim_player.play("idle")
		else:
			_idling = temp_idling
			if _idling >= _PATIENCE and \
			  (anim_player.current_animation != "bored0" and anim_player.current_animation != "bored1"):
				anim_player.play("bored0")
				anim_player.queue("bored1")

func _play_roll_animation() -> void:
	if sign(velocity.x) > 0.0:
		sprite.flip_h = false
	elif sign(velocity.x) < 0.0:
		sprite.flip_h = true
	if abs(velocity.x) >= _TOP_SPEED and anim_player.current_animation != "roll1":
		anim_player.play("roll1")
	elif abs(velocity.x) < _TOP_SPEED and anim_player.current_animation != "roll0":
		anim_player.play("roll0")
