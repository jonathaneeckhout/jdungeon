extends Node

signal enemy_added(enemy_name: String, enemy_class: String, pos: Vector2, loop_animation: String)
signal enemy_removed(enemy_name: String)

@rpc("call_remote", "authority", "reliable")
func add_enemy(enemy_name: String, enemy_class: String, pos: Vector2, loop_animation: String):
	enemy_added.emit(enemy_name, enemy_class, pos, loop_animation)


@rpc("call_remote", "authority", "reliable") func remove_enemy(enemy_name: String):
	enemy_removed.emit(enemy_name)
