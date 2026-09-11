extends Area3D

signal collected(pellet_node)

@onready var mesh_node: MeshInstance3D = $MeshInstance3D
var base_y: float = 0.5
var anim_offset: float = 0.0

func _ready() -> void:
	anim_offset = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	anim_offset += delta * 4.0
	mesh_node.position.y = base_y + sin(anim_offset) * 0.08
	mesh_node.rotate_y(delta * 2.5)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("pacman"):
		collected.emit(self)
		queue_free()
