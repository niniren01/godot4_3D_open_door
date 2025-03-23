extends StaticBody3D
@onready var player = get_tree().get_first_node_in_group("player")

@export var prompt := "open"
@export var prompt_input := "LMB"

const interactable := true
var interacted := false

func _ready() -> void:
	if player:
		player.connect("mouse_interact", _on_mouse_interact)

func _on_mouse_interact(interact_relative: Vector2) -> void:
	if interacted:
		rotation_degrees.y += interact_relative.x + interact_relative.y
		rotation_degrees.y = clamp(rotation_degrees.y, -110, 0)

func get_prompt() -> String:
	var prompt_message = "[" + prompt_input + "]: " + prompt
	return prompt_message

func interact(is_interacting: bool):
	interacted = is_interacting
