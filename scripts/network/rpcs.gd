extends Node

var account: Node
var player: Node
var clock: Node


func _ready():
	account = load("res://scripts/network/rpcs/account.gd").new()
	account.name = "Account"
	add_child(account)

	player = load("res://scripts/network/rpcs/player.gd").new()
	player.name = "Player"
	add_child(player)

	clock = load("res://scripts/network/rpcs/clock.gd").new()
	clock.name = "Clock"
	add_child(clock)
