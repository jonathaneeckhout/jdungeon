extends Resource

class_name ClassResource

@export_group("Base Stats")
@export var base_hp_max: int = 0
@export var base_energy_max: int = 0
@export var base_energy_regen: int = 0
@export var base_attack_power_min: int = 0
@export var base_attack_power_max: int = 0
@export var base_defense: int = 0
@export var base_movement_speed: float = 0

@export_group("Level Boost Stats")
@export var level_boost_hp_max: float = 1.0
@export var level_boost_energy_max: float = 1.0
@export var level_boost_energy_regen: float = 1.0
@export var level_boost_attack_power_min: float = 1.0
@export var level_boost_attack_power_max: float = 1.0
@export var level_boost_defense: float = 1.0
@export var level_boost_movement_speed: float = 1.0
