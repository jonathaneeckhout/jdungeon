extends Node

class_name NetworkMessageHandler

const COMPONENT_NAME = "NetworkMessageHandler"

# Reference to the MultiplayerConnection parent node.
var multiplayer_connection: MultiplayerConnection = null

var _message_mapper: Dictionary = {}

var _input_message_queue: Dictionary = {}
var _output_message_queue: Dictionary = {}

var bytes_per_second_out = 0
var bytes_per_second_in = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the MultiplayerConnection parent node.
	multiplayer_connection = get_parent()

	# Register the component with the parent MultiplayerConnection.
	multiplayer_connection.component_list.register_component(COMPONENT_NAME, self)

	# Wait until the multiplayer connection is initialized.
	await multiplayer_connection.init_done

	_map_childs()


func _physics_process(_delta: float):
	_handle_input_messages()
	_handle_output_messages()


func _handle_input_messages():
	for peer_id in _input_message_queue:
		_handle_peer_input_messages(peer_id, _input_message_queue[peer_id])

	_input_message_queue.clear()


func _handle_peer_input_messages(peer_id: int, messages: Array):
	for message in messages:
		_handle_peer_input_message(peer_id, message)


func _handle_peer_input_message(peer_id: int, message: PackedByteArray):
	var input_data: StreamPeerBuffer = StreamPeerBuffer.new()
	input_data.data_array = message

	var amount_of_messages: int = input_data.get_u16()
	for i in amount_of_messages:
		var message_size: int = input_data.get_u16()
		var message_data: PackedByteArray = input_data.get_data(message_size)[1]
		_map_input_message(peer_id, Seriously.unpack_from_bytes(message_data))


func _map_input_message(peer_id: int, message: Array):
	if message.size() < 2:
		return

	if not _message_mapper.has(message[0]):
		return

	_message_mapper[message[0]].handle_message(peer_id, message[1])


func _handle_output_messages():
	for peer_id in _output_message_queue:
		_handle_peer_output_messages(peer_id, _output_message_queue[peer_id])

	_output_message_queue.clear()


func _handle_peer_output_messages(peer_id: int, messages: Array):
	var output_data: StreamPeerBuffer = StreamPeerBuffer.new()
	output_data.put_u16(messages.size())

	for message in messages:
		var message_data: PackedByteArray = Seriously.pack_to_bytes(message)
		output_data.put_u16(message_data.size())
		output_data.put_data(message_data)

	bytes_per_second_out = output_data.get_size() / 0.05

	if peer_id in multiplayer_connection.multiplayer_api.get_peers():
		_send_message.rpc_id(peer_id, output_data.data_array)


func _map_childs():
	for child in get_children():
		if child.get("message_identifier") == null:
			GodotLogger.warn("Failed to map child=[%s], missing message identifier" % child.name)
			continue

		if _message_mapper.has(child.message_identifier):
			GodotLogger.warn(
				(
					"Failed to map child=[%s], message identifier=[%d] already mapped"
					% [child.name, child.message_identifier]
				)
			)
			continue

		GodotLogger.info(
			"Mapping child=[%s] to message identifier=[%d]" % [child.name, child.message_identifier]
		)

		_message_mapper[child.message_identifier] = child


func send_message(peer_id: int, identifier: int, message: Array):
	if _output_message_queue.has(peer_id):
		_output_message_queue[peer_id].append([identifier, message])
	else:
		_output_message_queue[peer_id] = [[identifier, message]]


@rpc("call_remote", "any_peer", "reliable")
func _send_message(message: PackedByteArray):
	bytes_per_second_in = message.size() / 0.05

	var peer_id = multiplayer_connection.multiplayer_api.get_remote_sender_id()
	if _input_message_queue.has(peer_id):
		_input_message_queue[peer_id].append(message)
	else:
		_input_message_queue[peer_id] = [message]
