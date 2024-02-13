extends Resource

class_name ClassResource

enum CLASSES { NONE, WARRIOR, RANGER, WIZARD }

@export var character_class: CLASSES = CLASSES.NONE

@export_group("Base Stats")
@export var base_hp_max: int = 100
@export var base_energy_max: int = 100
@export var base_energy_regen: int = 5
@export var base_attack_power_min: int = 0
@export var base_attack_power_max: int = 5
@export var base_defense: int = 0
@export var base_movement_speed: float = 300

@export_group("Level Boost Stats")
@export var level_boost_hp_max: float = 1.0
@export var level_boost_energy_max: float = 1.0
@export var level_boost_energy_regen: float = 1.0
@export var level_boost_attack_power_min: float = 1.0
@export var level_boost_attack_power_max: float = 1.0
@export var level_boost_defense: float = 1.0
@export var level_boost_movement_speed: float = 1.0
