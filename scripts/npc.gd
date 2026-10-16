extends Node2D

@export var npc_name: String = "Anciano Sabio"

@onready var interactive_area: Area2D = $InteractiveArea
@onready var hint_label: Label = $HintLabel
var player_nearby: bool = false

func _ready() -> void:
	hint_label.hide()
	interactive_area.body_entered.connect(
		_on_interactive_area_body_entered
	)
	interactive_area.body_exited.connect(
		_on_interactive_area_body_exited
	)

func _process(delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui == null:
		return

	# Si el diálogo ya está abierto, la tecla E pasa al siguiente mensaje
	if dialogue_ui.is_open:
		dialogue_ui.next_dialogue()
		return

	dialogue_ui.show_dialogue(npc_name, get_dialogues())

# Los mensajes cambian según el estado de la misión
func get_dialogues() -> Array[String]:
	match QuestManager.quest_state:
		QuestManager.QuestState.NOT_STARTED:
			QuestManager.start_quest()
			return [
				"¡Hola, viajero! Qué bueno que llegaste.",
				"Los guardias rojos robaron los %d cristales del templo." % QuestManager.required_crystals,
				"Tráemelos y ten cuidado: si te ven, te van a atacar."
			]
		QuestManager.QuestState.ACTIVE:
			var missing: int = QuestManager.required_crystals - QuestManager.collected_crystals
			return [
				"Todavía te faltan %d cristales." % missing,
				"Búscalos por el laberinto y vuelve cuando los tengas."
			]
		QuestManager.QuestState.READY_TO_DELIVER:
			QuestManager.complete_quest()
			return [
				"¡Increíble, trajiste todos los cristales!",
				"Gracias a ti el templo está a salvo. ¡Eres un verdadero guardián del cristal!"
			]
		_:
			return [
				"Gracias otra vez por recuperar los cristales."
			]

func _on_interactive_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		hint_label.show()


func _on_interactive_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		hint_label.hide()

		# Si el jugador se aleja, se cierra la conversación
		var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
		if dialogue_ui != null and dialogue_ui.is_open:
			dialogue_ui.close_dialogue()
