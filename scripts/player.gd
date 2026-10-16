extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 220.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.5

var health: int
var is_dead: bool = false
var attack_timer: float = 0.0

@onready var attack_area: Area2D = $AttackArea
@onready var healthBar: ProgressBar = $HealthBar
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	healthBar.max_value = max_health
	healthBar.value = health

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	attack_timer = maxf(attack_timer - _delta, 0.0)
	if Input.is_action_just_pressed("player_attack"):
		attack()

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
        "move_down"
	)

	velocity = direction * speed
	move_and_slide()
	
func attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)
				animatedSprite.play("attack")


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	healthBar.value = health

	if health == 0:
		is_dead = true
		died.emit()
