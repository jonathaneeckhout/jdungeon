extends Node

@rpc("call_remote", "authority", "reliable")
func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	Gmf.signals.client.enemy_added.emit(enemy_name, enemy_class, pos)
