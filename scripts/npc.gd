extends Node2D

@onready var interactive_area: Area2D = $InteractiveArea
var player_nearby: bool = false

func _ready() -> void:
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
	var dialogue_ui = 

func _on_interactive_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_interactive_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
