extends Node2D

@onready var crystal_label: Label = \
	$UI/HUD/CrystalLabel

func _ready() -> void:
	# La misión pide tantos cristales como haya en el mapa
	QuestManager.required_crystals = $crystals.get_child_count()

	# El texto se actualiza cada vez que cambia la misión
	QuestManager.quest_updated.connect(update_crystal_label)

	update_crystal_label()

func update_crystal_label() -> void:
	match QuestManager.quest_state:
		QuestManager.QuestState.NOT_STARTED:
			crystal_label.text = "Misión: habla con el anciano (E)"
		QuestManager.QuestState.ACTIVE:
			crystal_label.text = "Cristales: %d / %d" % [
				QuestManager.collected_crystals,
				QuestManager.required_crystals
			]
		QuestManager.QuestState.READY_TO_DELIVER:
			crystal_label.text = "Cristales: %d / %d - ¡Vuelve con el anciano!" % [
				QuestManager.collected_crystals,
				QuestManager.required_crystals
			]
		QuestManager.QuestState.COMPLETED:
			crystal_label.text = "¡Misión completada!"
