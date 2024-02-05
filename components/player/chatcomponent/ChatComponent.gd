extends Node

class_name ChatComponent

const COMPONENT_NAME: String = "chat"

enum MESSAGE_TYPE { MAP, WHISPER }

signal message_received(type: MESSAGE_TYPE, from: String, message: String)

var _target_node: Node

var _chat_server_rpc: ChatServerRPC = null


func _ready():
	_target_node = get_parent()

	assert(_target_node.multiplayer_connection != null, "Target's multiplayer connection is null")

	if _target_node.get("component_list") != null:
		_target_node.component_list[COMPONENT_NAME] = self

	# Get the ChatServerRPC component.
	_chat_server_rpc = _target_node.multiplayer_connection.component_list.get_component(
		ChatServerRPC.COMPONENT_NAME
	)

	# Ensure the ChatServerRPC component is present
	assert(_chat_server_rpc != null, "Failed to get ChatServerRPC component")


func client_send_message(message_type: MESSAGE_TYPE, to: String, message: String):
	match message_type:
		MESSAGE_TYPE.MAP:
			_chat_server_rpc.send_map_message(message)
		MESSAGE_TYPE.WHISPER:
			GodotLogger.info(
				"Whisper messaging is not yet implemented, can't send message to %s" % to
			)


func client_receive_map_message(from: String, message: String):
	message_received.emit(MESSAGE_TYPE.MAP, from, message)


func message_type_to_string(message_type: MESSAGE_TYPE) -> String:
	match message_type:
		MESSAGE_TYPE.MAP:
			return "Map"
		MESSAGE_TYPE.WHISPER:
			return "Whisper"

	return "Unkown"
