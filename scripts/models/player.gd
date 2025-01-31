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

signal game_over

const _GRAVITY: float = (56.0 / 256.0) * 120.0
const _AIR_ACCELERATION: float = (24.0 / 256.0) * 120.0
const _AIR_DRAG: float = (8.0 / 256.0) * 120.0
const _TOP_Y_SPEED: float = 16.0 * 120.0
const _JUMP_FORCE: float = 6.5 * 60.0
const _ACCELERATION: float = (12.0 / 256.0) * 120.0
const _DECELERATION: float = 0.5 * 120.0
const _FRICTION: float = _ACCELERATION
const _TOP_SPEED: float = 6.0 * 60.0
const _PATIENCE: float = 3.0
const _MAX_PATIENCE: float = _PATIENCE * 60.0
const _ROLL_FRICTION: float = _ACCELERATION / 2.0
const _ROLL_DECELERATION: float = (32.0 / 256.0) * 120.0
const _SLOPE_FACTOR: float = (32.0 / 256.0) * 120.0
const _SLOPE_FACTOR_ROLLUP: float = (20.0 / 256.0) * 120.0
const _SLOPE_FACTOR_ROLLDOWN: float = _SLOPE_FACTOR_ROLLUP * 2.0

var _control_lock: float = 0.0
var _idling: float = 0.0
var _is_jumping: bool = false
var _is_rolling: bool = false
var _is_charging: bool = false
var _spinrev: float = 0.0
var _charges: int = 0
var _audio_buffer: float = 0.0
var _is_spinning_out: bool = false

var active: bool = true
var peeling_out: float = 0.0

func _ready() -> void:
	pass

func _physics_process(delta) -> void:
	if not active:
		return
	var movement_input: Vector2 = Input.get_vector("game_left", "game_right", "game_down", "game_up", 0.35)
	var real_velocity: Vector2 = get_real_velocity()
	var on_floor: bool = is_on_floor()
	var on_wall: bool = is_on_wall()
	var floor_angle: float = rad_to_deg(get_floor_angle())
	var wall_normals: Vector2 = Vector2.ZERO
	movement_input = round(movement_input)
	if _audio_buffer:
		_audio_buffer = move_toward(_audio_buffer, 0.0, delta)
	if _is_jumping and on_floor:
		_is_jumping = false
	if _is_rolling and on_floor and real_velocity and (abs(velocity.x) == 0.0 or on_wall):
		_is_rolling = false
	if _is_charging and movement_input.y >= 0.0:
		_is_charging = false
		print("charging false")
		_spinrev = 0.0
		_charges = 0
	if on_wall:
		wall_normals = get_wall_normal()
	if not on_floor and velocity.y < -_TOP_SPEED * 0.25 and not Input.is_action_pressed("game_action"):
		velocity.y = -_TOP_SPEED * 0.25
	if not on_floor and real_velocity.y < 0.0 and real_velocity.y > -4.0:
		velocity.x = move_toward(velocity.x, 0.0, floor(abs(velocity.x) * 8.0) / 256.0)
	if not on_floor or (floor_angle > 45.0 and velocity.x < _TOP_SPEED * 0.33):
		velocity.y = move_toward(velocity.y, _TOP_Y_SPEED, _GRAVITY)
	elif on_floor and velocity.x != 0.0 and floor_angle != 0.0 and movement_input.x != 0.0:
		var floor_normals: Vector2 = get_floor_normal()
		print(floor_normals)
		if not _is_rolling:
			velocity.x += _SLOPE_FACTOR * sign(floor_normals.x) * abs(floor_normals.x)
		elif _is_rolling and sign(velocity.x) != sign(floor_normals.x):
			velocity.x += _SLOPE_FACTOR_ROLLUP * sign(floor_normals.x) * abs(floor_normals.x)
		elif _is_rolling and sign(velocity.x) == sign(floor_normals.x):
			velocity.x += _SLOPE_FACTOR_ROLLDOWN * sign(floor_normals.x) * abs(floor_normals.x)
	elif movement_input == Vector2.ZERO and real_velocity == Vector2.ZERO:
		_idling += delta
		if _idling >= _MAX_PATIENCE:
			game_over.emit()
	if not _control_lock and not on_floor and movement_input.x != 0.0 and not on_wall:
		velocity.x = move_toward(velocity.x, sign(movement_input.x) * _TOP_SPEED, _AIR_ACCELERATION)
	elif not _control_lock and _is_charging and on_floor and movement_input.y < 0.0:
		_spinrev = move_toward(_spinrev, 0.0, floor(_charges / 0.125) / 256.0)
		if Input.is_action_just_pressed("game_action"):
			_charges += 2
			_charges = clamp(_charges, 0, 8)
			if _charges < 8:
				_spinrev += 2.0
				_spinrev = clamp(_spinrev, 0.0, 8.0)
		print("[%s]: %f" % [Time.get_datetime_string_from_system(), 8.0 + (floor(_spinrev) / 2.0)])
	elif not _control_lock and not _is_charging and on_floor and movement_input.y < 0.0 and velocity.x == 0.0:
		_is_charging = true
		print("charging true")
	elif not _control_lock and on_floor and velocity.x != 0.0 and movement_input.y < 0.0:
		_is_rolling = true
	elif not _control_lock and on_floor and Input.is_action_just_pressed("game_action"):
		_is_jumping = true
		velocity = real_velocity
		velocity += _JUMP_FORCE * get_floor_normal()
		if velocity.x < 0.0 and not sprite.flip_h:
			sprite.flip_h = true
		elif velocity.x > 0.0 and sprite.flip_h:
			sprite.flip_h = false
	elif not _control_lock and not _is_jumping and _is_rolling and on_floor and real_velocity.x != 0.0:
		velocity.x = move_toward(velocity.x, 0.0, _ROLL_FRICTION)
		if on_wall:
			velocity.x = 0.0
		if sign(movement_input.x) != 0.0 and sign(movement_input.x) != sign(velocity.x):
			velocity.x = move_toward(velocity.x, 0.0, _ROLL_DECELERATION)
	elif not _control_lock and on_floor and velocity.x != 0.0 and movement_input.x == 0.0 and not on_wall:
		velocity.x = move_toward(velocity.x, 0.0, _FRICTION)
	elif not _control_lock and on_floor and movement_input.x != 0.0:
		if velocity.x != 0.0 and sign(movement_input.x) != sign(velocity.x):
			if _DECELERATION > abs(velocity.x) or on_wall:
				velocity.x = -sign(velocity.x) * _DECELERATION
			else:
				velocity.x = move_toward(velocity.x, 0.0, _DECELERATION)
		else:
			if on_wall and sign(wall_normals.x) != velocity.x:
				velocity.x = 0.0
			velocity.x = move_toward(velocity.x, sign(movement_input.x) * _TOP_SPEED, _ACCELERATION)
		if velocity.x < 0.0 and not sprite.flip_h:
			sprite.flip_h = true
		elif velocity.x > 0.0 and sprite.flip_h:
			sprite.flip_h = false
	move_and_slide()
	on_floor = is_on_floor()
	real_velocity = get_real_velocity()
	floor_angle = get_floor_angle()
	if real_velocity != Vector2.ZERO:
		_idling = 0.0
	_handle_animation(real_velocity, on_floor, movement_input, floor_angle, on_wall, wall_normals)

func _handle_animation(real_velocity: Vector2, on_floor: bool, movement_input: Vector2, \
  floor_angle: float, on_wall: bool, wall_normals: Vector2) -> void:
	if _is_jumping:
		if anim_player.current_animation != "roll0" and anim_player.current_animation != "roll1":
			_play_roll_animation()
	elif _is_rolling and velocity.x < _TOP_SPEED * 0.67:
		if anim_player.current_animation != "roll0":
			anim_player.play("roll0")
	elif _is_rolling and velocity.x >= _TOP_SPEED * 0.67:
		if anim_player.current_animation != "roll1":
			anim_player.play("roll1")
	elif _is_charging and _charges == 8:
		if anim_player.current_animation != "roll1":
			anim_player.play("roll1")
	elif _is_charging and _charges > 0:
		if anim_player.current_animation != "roll0":
			anim_player.play("roll0")
	elif _is_charging:
		if anim_player.current_animation != "look_down":
			anim_player.play("look_down")
	elif on_floor and on_wall and sign(movement_input.x) != sign(wall_normals.x):
		if sign(movement_input.x) > 0.0 and anim_player.current_animation != "push_r":
			anim_player.play("push_r")
		elif sign(movement_input.x) < 0.0 and anim_player.current_animation != "push_l":
			anim_player.play("push_l")
	elif on_floor and velocity.x != 0.0 and abs(velocity.x) >= _TOP_SPEED * 0.1 \
	  and sign(movement_input.x) != 0.0 and sign(velocity.x) != sign(movement_input.x):
		if anim_player.current_animation != "brake":
			anim_player.play("brake")
	elif on_floor and velocity.x != 0.0 and (peeling_out or abs(velocity.x) > _TOP_SPEED):
		if anim_player.current_animation != "run2":
			anim_player.play("run2")
	elif on_floor and velocity.x != 0.0 and abs(velocity.x) == _TOP_SPEED:
		if anim_player.current_animation != "run1":
			anim_player.play("run1")
	elif on_floor and velocity.x != 0.0 and abs(velocity.x) >= _TOP_SPEED * 0.67:
		if anim_player.current_animation != "run0_1":
			anim_player.play("run0_1") 
	elif on_floor and velocity.x != 0.0 and abs(velocity.x) < _TOP_SPEED * 0.67:
		if anim_player.current_animation != "run0":
			anim_player.play("run0")
	elif on_floor and not velocity and not real_velocity and movement_input.y > 0.0:
		if anim_player.current_animation != "look_up":
			anim_player.play("look_up")
	elif _idling > _PATIENCE:
		if anim_player.current_animation != "bored0" and anim_player.current_animation != "bored1":
			anim_player.play("bored0")
			anim_player.queue("bored1")
	elif _idling > 0.0:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
	if abs(real_velocity.y) <= 60.0 * 0.01 or rad_to_deg(floor_angle) < 45.0:
		rotation_degrees = 0.0
	else:
		rotation_degrees = sign(get_floor_normal().x) * 45.0

func _play_roll_animation() -> void:
		var air_speed: float = Vector2.ZERO.distance_to(get_last_motion())
		if air_speed > 60.0 * 0.167:
			if anim_player.current_animation != "roll1":
				anim_player.play("roll1")
		elif air_speed < 60.0 * 0.167:
			if anim_player.current_animation != "roll0":
				anim_player.play("roll0")

#func _physics_process(delta: float) -> void:
	#if (not active):
		#return
	#if _idling >= _MAX_PATIENCE:
		#active = false
		#anim_player.play("outta_here")
		#audio_player.stream = _sfx_outta_here
		#audio_player.play()
		#game_over.emit()
		#return
	#_control_lock = max(_control_lock - delta, 0.0)
	#var action_pressed: bool = Input.is_action_just_pressed("game_action")
	#var move_direction: Vector2 = Input.get_vector("game_left", "game_right", "game_down", "game_up")
	#var real_input: Vector2 = move_direction
	#var temp_spinrev: float = _spinrev
	#_spinrev = 0.0
	#_audio_buffer = max(_audio_buffer - delta, 0.0)
	#temp_spinrev = clamp(temp_spinrev - ((8.0 / 256.0) * delta), 0.0, 8.0)
	#if _control_lock > 0.0:
		#move_direction.x = 0.0
	#if move_direction.x != 0.0:
		#move_direction.y = 0.0
	#if (not is_on_floor()) or \
	  #(rad_to_deg(get_floor_normal().angle()) + 90.0 > 45.0 or \
	  #rad_to_deg(get_floor_normal().angle()) + 90.0 < -45.0):
		#velocity.y = min((velocity.y + _GRAVITY), _TOP_Y_SPEED)
	#if not is_on_floor():
		#if _is_jumping and not Input.is_action_pressed("game_action"):
			#if velocity.y < 0.0:
				#velocity.y = max(velocity.y, -4.0 * 60.0, 0.0)
		#velocity.x = velocity.x + (move_direction.x * _AIR_ACCELERATION)
		#if velocity.y == clamp(velocity.y, -4.0 * 60, 0.0):
			#velocity.x -= move_direction.x * _AIR_DRAG * delta
	#else:
		#_is_jumping = false
		#if _is_spinning_out and (abs(velocity.x) <= 3.0 * 60.0 or move_direction.y > 0.0):
			#_is_spinning_out = false
		#if velocity.x == 0.0 and move_direction.y < 0.0:
			#_spinrev = temp_spinrev
		#if temp_spinrev > 0.0 and move_direction.y >= 0.0:
			#var launch_speed = 8.0 + (_spinrev / 2.0)
			#if not sprite.flip_h:
				#velocity.x = launch_speed * 60.0
			#else:
				#velocity.x = -launch_speed * 60.0
			#_is_spinning_out = true
			#_spinrev = 0.0
			#if audio_player.stream != _sfx_release:
				#audio_player.stream = _sfx_release
			#audio_player.play()
		#elif (action_pressed and real_input.y >= 0.0 and velocity.x == 0.0) or \
		  #(action_pressed and velocity.x != 0.0):
			#_is_jumping = true
			#velocity.y = max(velocity.y - _JUMP_FORCE, -_TOP_Y_SPEED)
			#if audio_player.stream != _sfx_jump:
				#audio_player.set_stream(_sfx_jump)
			#audio_player.play()
		#if action_pressed and velocity.x == 0.0 and move_direction.y < 0.0:
			#_spinrev = min(temp_spinrev + 2.0, 8.0)
			#print(_spinrev)
			#if audio_player.stream != _sfx_charge:
				#audio_player.set_stream(_sfx_charge)
			#if _audio_buffer <= 0.0 or not audio_player.playing:
				#_audio_buffer = 0.178
				#audio_player.play()
		#elif real_input.x == 0.0:
			#if sign(velocity.x) > 0.0:
				#velocity.x = max(velocity.x - _FRICTION, 0.0)
			#else:
				#velocity.x = min(velocity.x + _FRICTION, 0.0)
		#else:
			#if move_direction.y < 0.0:
				#if velocity.x > 0.0 and sign(real_input.x) != sign(velocity.x):
					#velocity.x = max(velocity.x - _ROLL_DECELERATION, 0.0)
				#elif velocity.x < 0.0 and sign(real_input.x) != sign(velocity.x):
					#velocity.x = min(velocity.x + _ROLL_DECELERATION, 0.0)
				#elif velocity.x > 0.0:
					#velocity.x = max(velocity.x - _ROLL_FRICTION, 0.0)
				#elif velocity.x < 0.0:
					#velocity.x = min(velocity.x + _ROLL_FRICTION, 0.0)
			#elif sign(move_direction.x) == sign(velocity.x) or sign(velocity.x) == 0.0:
				#velocity.x = clamp(velocity.x + (move_direction.x * _ACCELERATION), -_TOP_SPEED, _TOP_SPEED)
			#else:
				#var original_sign: float = sign(velocity.x)
				#velocity.x -= original_sign * _DECELERATION
				#if sign(velocity.x) != original_sign:
					#velocity.x = -original_sign * 0.5
				#if abs(velocity.x) > 2.0 * 60.0:
					#if audio_player.stream != _sfx_brake:
						#audio_player.set_stream(_sfx_brake)
					#if not audio_player.playing:
						#audio_player.play()
	#_handle_animations(delta, move_direction)
	#move_and_slide()
	#var angle: float = get_floor_normal().angle() + deg_to_rad(90.0)
	#if not is_on_floor():
		#angle -= deg_to_rad(90.0)
	#var snapped_angle: float = round(angle / (PI / 4.0)) * (PI / 4.0)
	#rotation = round(angle / (PI / 4.0)) * (PI / 4.0)
#
#func _handle_animations(delta: float, move_direction: Vector2) -> void:
	#var temp_idling: float = min(_idling + delta, _PATIENCE * 60.0)
	#_idling = 0.0
	#if (sign(move_direction.x) > 0.0 and sprite.flip_h) \
	  #or (sign(move_direction.x) < 0.0 and not sprite.flip_h):
		#sprite.flip_h = not sprite.flip_h
	#if _is_jumping or _is_spinning_out:
		#_play_roll_animation()
	#else:
		#if not is_on_floor() and velocity.y >= _TOP_Y_SPEED / 2.0:
			#if not anim_player.current_animation == "fall":
				#anim_player.play("fall")
		#elif not is_on_floor() and velocity.y < _TOP_Y_SPEED / 2.0:
			#if velocity.x == 0.0 and not anim_player.current_animation == "idle":
				#anim_player.play("idle")
			#elif velocity.x != 0.0:
				#if abs(velocity.x) >= _TOP_SPEED * 0.67:
					#anim_player.play("run0_1")
				#else:
					#anim_player.play("run0")
		#elif is_on_floor() and velocity.x != 0.0:
			#if is_on_floor() and is_on_wall() and move_direction.x != 0.0:
				#if not anim_player.current_animation == "push_r" and not sprite.flip_h:
					#anim_player.play("push_r")
				#elif not anim_player.current_animation == "push_l" and sprite.flip_h:
					#anim_player.play("push_l")
			#elif velocity.x != 0.0 and move_direction.y < 0.0:
				#_play_roll_animation()
			#elif velocity.x != 0.0 and (sign(move_direction.x) == sign(velocity.x) or move_direction.x == 0.0):
				#if sign(velocity.x) > 0.0:
					#sprite.flip_h = false
				#else:
					#sprite.flip_h = true
				#if (abs(velocity.x) > _TOP_SPEED or peeling_out >= 0.1) and \
				  #anim_player.current_animation != "run2":
					#anim_player.play("run2")
				#elif abs(velocity.x) >= _TOP_SPEED and \
				  #(anim_player.current_animation != "run1" or anim_player.current_animation != "run2"):
					#anim_player.play("run1")
				#elif abs(velocity.x) >= _TOP_SPEED * 0.67:
					#if anim_player.current_animation == "run0":
						#var frame: int = sprite.frame + 1
						#anim_player.play("run0_1")
						#anim_player.seek((frame - 12) * 0.05)
					#else:
						#anim_player.play("run0_1")
				#else:
					#anim_player.play("run0")
			#elif abs(velocity.x) > 2.0 * 60.0 and \
			  #(anim_player.current_animation != "roll0" or anim_player.current_animation != "roll1"):
				#anim_player.play("brake")
		#elif is_on_floor() and move_direction.y != 0.0:
			#if move_direction.y > 0.0:
				#if anim_player.current_animation != "look_up":
					#anim_player.play("look_up")
			#elif _spinrev > 0.0:
				#if _spinrev >= 6.0:
					#if anim_player.current_animation != "roll1":
						#anim_player.play("roll1")
				#elif anim_player.current_animation != "roll0":
					#anim_player.play("roll0")
			#elif anim_player.current_animation != "look_down":
				#anim_player.play("look_down")
		#elif anim_player.current_animation != "idle" and temp_idling < _PATIENCE:
			#_idling = temp_idling
			#anim_player.play("idle")
		#else:
			#_idling = temp_idling
			#if _idling >= _PATIENCE and \
			  #(anim_player.current_animation != "bored0" and anim_player.current_animation != "bored1"):
				#anim_player.play("bored0")
				#anim_player.queue("bored1")
#
#func _play_roll_animation() -> void:
	#if sign(velocity.x) > 0.0:
		#sprite.flip_h = false
	#elif sign(velocity.x) < 0.0:
		#sprite.flip_h = true
	#if abs(velocity.x) >= _TOP_SPEED and anim_player.current_animation != "roll1":
		#anim_player.play("roll1")
	#elif abs(velocity.x) < _TOP_SPEED and anim_player.current_animation != "roll0":
		#anim_player.play("roll0")
