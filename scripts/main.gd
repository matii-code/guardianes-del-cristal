extends Node2D

var crystals_collected: int = 0
var total_crystals: int = 0

@onready var crystal_label: Label = \
	$UI/HUD/CrystalLabel
@onready var health_bar: ProgressBar = \
	$UI/HUD/HealthBar
@onready var game_over_label: Label = \
	$UI/HUD/GameOverLabel
@onready var player = $player

func _ready() -> void:
	var crystals := $crystals.get_children()

	total_crystals = crystals.size()

	for crystal in crystals:
		crystal.collected.connect(
			_on_crystal_collected
		)

	update_crystal_label()

	# Barra de vida del jugador: baja cada vez que un guardia lo golpea
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

func _on_crystal_collected() -> void:
	crystals_collected += 1
	update_crystal_label()

	if crystals_collected >= total_crystals:
		print("¡Todos los cristales recolectados!")

func update_crystal_label() -> void:
	crystal_label.text = "Cristales: %d / %d" % [
		crystals_collected,
		total_crystals
	]

func _on_player_health_changed(current: int, _maximum: int) -> void:
	health_bar.value = current

func _on_player_died() -> void:
	game_over_label.visible = true
