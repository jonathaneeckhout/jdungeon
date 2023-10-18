extends Node


func _ready():
	J.rpcs.player.message_sent.connect(_on_message_sent)


func _on_message_sent(from: int, type: String, to: String, message: String):
	var from_player: JPlayerBody2D = J.world.get_player_by_peer_id(from)

	if from_player == null:
		J.logger.info("Invalid player")
		return

	match type:
		# Send the message to everybody on the server
		"Global":
			for to_player in J.world.players.get_children():
				J.rpcs.player.receive_message.rpc_id(
					to_player.peer_id, type, from_player.username, message
				)
		# Send the message to everybody in the local network sync area
		"Local":
			for to_player in from_player.synchronizer.watchers:
				J.rpcs.player.receive_message.rpc_id(
					to_player.peer_id, type, from_player.username, message
				)
