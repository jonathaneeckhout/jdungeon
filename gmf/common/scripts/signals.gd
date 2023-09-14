extends Node

signal player_added
signal player_removed

var server: Node
var client: Node


func init_server():
	server = load("res://gmf/server/scripts/signals.gd").new()
	server.name = "Server"
	add_child(server)


func init_client():
	client = load("res://gmf/client/scripts/signals.gd").new()
	client.name = "Client"
	add_child(client)
