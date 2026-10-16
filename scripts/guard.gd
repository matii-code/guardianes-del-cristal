extends CharacterBody2D

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN
}

@export var patrol_speed: float = 70.0
@export var chase_speed: float = 115.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
@export var attack_exit_distance: float = 60.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detectionArea: Area2D = $DetectionArea
@onready var attackArea: Area2D = $AttackArea
@onready var position_a: Marker2D = $"PositionPatrol A"
@onready var position_b: Marker2D = $"PositionPatrol B"

var state: State = State.IDLE
var player: CharacterBody2D = null
var patrol_position: Array[Vector2] = []
var patrol_index: int = 0
var home_position: Vector2

var attack_timer: float = 0.0
var idle_timer: float = 1.0

func _ready() -> void:
	home_position = global_position

	# Los puntos de patrulla se guardan en coordenadas globales para que no se muevan con el guardia
	patrol_position = [
		position_a.global_position,
		position_b.global_position
	]

	change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)

	# Si el jugador murió, el guardia deja de perseguirlo
	if player != null and player.is_dead:
		player = null
		if state == State.CHASE or state == State.ATTACK:
			change_state(State.RETURN)

	match state:
		State.IDLE:
			idle_state(delta)
		State.PATROL:
			patrol_state()
		State.CHASE:
			chase_state()
		State.ATTACK:
			attack_state()
		State.RETURN:
			return_state()

	move_and_slide()

func change_state(new_state: State) -> void:
	state = new_state

	match state:
		State.IDLE:
			idle_timer = 1.0
			velocity = Vector2.ZERO
			sprite.play("idle")
		State.PATROL:
			sprite.play("patrol")
		State.CHASE:
			sprite.play("chase")
		State.ATTACK:
			velocity = Vector2.ZERO
			sprite.play("attack")
		State.RETURN:
			sprite.play("patrol")

# IDLE: espera un momento en el punto de patrulla antes de ir al siguiente
func idle_state(delta: float) -> void:
	velocity = Vector2.ZERO
	idle_timer -= delta
	if idle_timer <= 0.0:
		change_state(State.PATROL)

# PATROL: camina entre el punto A y el punto B
func patrol_state() -> void:
	var target := patrol_position[patrol_index]
	move_towards(target, patrol_speed)

	# Llegó al punto, o una pared lo bloquea: espera y cambia de punto
	if global_position.distance_to(target) < 5.0 or is_blocked_by_wall():
		patrol_index = (patrol_index + 1) % patrol_position.size()
		change_state(State.IDLE)

# CHASE: persigue al jugador hasta tenerlo en rango de ataque
func chase_state() -> void:
	if player == null:
		change_state(State.RETURN)
		return

	if attackArea.overlaps_body(player):
		change_state(State.ATTACK)
		return

	move_towards(player.global_position, chase_speed)

# ATTACK: se queda quieto y golpea al jugador cada attack_cooldown segundos
func attack_state() -> void:
	velocity = Vector2.ZERO

	if player == null:
		change_state(State.RETURN)
		return

	# Sólo vuelve a perseguir si el jugador se aleja de verdad (evita cambiar de estado a cada rato)
	if global_position.distance_to(player.global_position) > attack_exit_distance:
		change_state(State.CHASE)
		return

	face_towards(player.global_position)

	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		sprite.stop()
		sprite.play("attack")
		play_attack_lunge()
		player.take_damage(attack_damage)

# RETURN: vuelve a su posición inicial y retoma la patrulla
func return_state() -> void:
	move_towards(home_position, patrol_speed)

	if global_position.distance_to(home_position) < 5.0 or is_blocked_by_wall():
		change_state(State.PATROL)

# Está chocando contra una pared y además intenta seguir caminando hacia ella
func is_blocked_by_wall() -> bool:
	return is_on_wall() and get_wall_normal().dot(velocity) < 0.0

func move_towards(target: Vector2, speed: float) -> void:
	velocity = global_position.direction_to(target) * speed
	face_towards(target)

func face_towards(target: Vector2) -> void:
	# La animación de caminar mira a la izquierda, se voltea para mirar a la derecha
	if absf(target.x - global_position.x) > 1.0:
		sprite.flip_h = target.x > global_position.x

# Pequeño empujón del sprite hacia el jugador al golpear
func play_attack_lunge() -> void:
	var direction := global_position.direction_to(player.global_position)
	var tween := create_tween()
	tween.tween_property(sprite, "position", direction * 18.0, 0.08)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.15)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not body.is_dead:
		player = body
		if state != State.ATTACK:
			change_state(State.CHASE)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		change_state(State.RETURN)
