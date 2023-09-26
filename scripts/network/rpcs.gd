extends Node

var account: Node
var player: Node
var enemy: Node
var item: Node
var clock: Node


func _ready():
	account = load("res://scripts/network/rpcs/account.gd").new()
	account.name = "Account"
	add_child(account)

	player = load("res://scripts/network/rpcs/player.gd").new()
	player.name = "Player"
	add_child(player)

	enemy = load("res://scripts/network/rpcs/enemy.gd").new()
	enemy.name = "Enemy"
	add_child(enemy)

	item = load("res://scripts/network/rpcs/item.gd").new()
	item.name = "Item"
	add_child(item)

	clock = load("res://scripts/network/rpcs/clock.gd").new()
	clock.name = "Clock"
	add_child(clock)
