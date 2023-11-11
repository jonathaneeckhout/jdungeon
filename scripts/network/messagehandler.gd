extends Node

class_name MessageHandler


func _ready():
	G.player_rpc.message_sent.connect(_on_message_sent)


func _on_message_sent(from: int, type: String, to: String, message: String):
	var from_player: Player = G.world.get_player_by_peer_id(from)

	if from_player == null:
		GodotLogger.info("Invalid player")
		return

	match type:
		# Send the message to everybody on the server
		"Global":
			for to_player in G.world.players.get_children():
				G.player_rpc.receive_message.rpc_id(
					to_player.peer_id, type, from_player.username, message
				)
		# Send the message to everybody in the local network sync area
		"Local":
			for to_player in from_player.synchronizer.watchers:
				G.player_rpc.receive_message.rpc_id(
					to_player.peer_id, type, from_player.username, message
				)
		# Send the message to only the target player
		"Whisper":
			var to_player: Player = G.world.get_player_by_username(to)
			if not to_player:
				GodotLogger.info("Player=[%s] does not exist" % to)
				return

			if to_player != from_player:
				# Send the message to the player
				G.player_rpc.receive_message.rpc_id(
					to_player.peer_id, type, from_player.username, message
				)
			# But also to yourself
			G.player_rpc.receive_message.rpc_id(
				from_player.peer_id, type, from_player.username, message
			)
