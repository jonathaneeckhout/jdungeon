extends Node

@rpc("call_remote", "authority", "reliable")
func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2):
	GMF.signals.client.enemy_added.emit(enemy_name, enemy_class, pos)


@rpc("call_remote", "authority", "reliable") func remove_enemy(enemy_name: String):
	GMF.signals.client.enemy_removed.emit(enemy_name)
