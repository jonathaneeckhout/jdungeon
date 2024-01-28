extends Node2D

class_name WatcherSynchronizerComponent

# Make sure this value is very small
@export var network_visible_area_size: float = 1.0

var target_node: Node
var watchers: Array[Node2D] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	target_node = get_parent()

	assert(target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if not target_node.multiplayer_connection.is_server():
		return

	var cs_network_visible_circle = CircleShape2D.new()
	cs_network_visible_circle.radius = network_visible_area_size

	var cs_body_network_visible_area = CollisionShape2D.new()
	cs_body_network_visible_area.name = "BodyNetworkVisibleAreaCollisionShape2D"
	cs_body_network_visible_area.shape = cs_network_visible_circle

	var body_network_visible_area = Area2D.new()
	body_network_visible_area.name = "BodyNetworkVisibleViewArea"
	body_network_visible_area.collision_layer = 0
	body_network_visible_area.collision_mask = J.PHYSICS_LAYER_NETWORKING
	body_network_visible_area.add_child(cs_body_network_visible_area)

	add_child(body_network_visible_area)

	body_network_visible_area.area_entered.connect(_on_area_network_visible_area_entered)
	body_network_visible_area.area_exited.connect(_on_area_network_visible_area_exited)


func _on_area_network_visible_area_entered(area: Area2D):
	var network_view_synchronizer: NetworkViewSynchronizerComponent = area.get_parent()

	if network_view_synchronizer.target_node == target_node:
		return

	if network_view_synchronizer.target_node.get("peer_id") == null:
		GodotLogger.info("Body's target_node does not contain peer_id")
		return

	if not watchers.has(network_view_synchronizer.target_node):
		watchers.append(network_view_synchronizer.target_node)


func _on_area_network_visible_area_exited(area: Area2D):
	var network_view_synchronizer: NetworkViewSynchronizerComponent = area.get_parent()

	if network_view_synchronizer.target_node == target_node:
		return

	if watchers.has(network_view_synchronizer.target_node):
		watchers.erase(network_view_synchronizer.target_node)
