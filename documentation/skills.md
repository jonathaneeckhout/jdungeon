# Skill system

## Overview
This system uses `SkillComponentResource` resources to define new skills that a player can use. Which are then handled by the `SkillComponent` node.  
Each `SkillComponent` can hold an arbitrary amount of skills. Despite holding a direct reference to said skills, this system relies mostly on the `SkillComponentResource.skill_class` (of `String` type) property to identify skills over the network.     
Like other resources, these are registered in the `J` singleton with `J.register_skill_resource(skill_class: String, resource_path: String)`

## Networking side  
If a skill has been selected and the action button is pressed, `PlayerSynchronizer._handle_right_click()` sends the class of the chosen skill to the server, as well as a global position of where it was used. The server, after running checks like distance to target or if the player even owns said skill. It then uses the `SkillComponentResource.skill_class` received to load the correct skill resource and runs `SkillComponentResource.effect()` in the desired location.  

## `SkillComponent.UseInfo`  
This object is used to carry information about how the skill was used and is created by `SkillComponent` before being passed onto the selected skill, `SkillComponentResource` has NO reason to modify this object as doing so won't have any effect.   
It contains some methods to retrieve information like the `StatsSynchronizerComponent` of all targets about to be affected by the skill.  
Check the `SkillComponent` script to see all of the information it holds.

## Creating your own skills
Unless the skill's only purpose is to deal damage or heal (by modifying it's "damage" property to be positive or negative). You will need a new script.  
The script can be added by first creating a regular SkillComponentResource resource file. Then in the inspector, navigating to the bottom to the "script" property, where you can add a new one. You may load an existing .gd file or create it right in the field as an internal Script resource. The script must extend `SkillComponentResource`.  
  
From there, the script must override the `_effect(usageInformation: SkillComponent.UseInfo)` function to implement your own functionality. As an example, here is the script for the "HealSelf" spell which heals the user by 20 HP.

```
extends SkillComponentResource

func _effect(info: SkillComponent.UseInfo):
	info.get_user_stats().heal(info.user.get_name(), 20)
```


## Advanced `SkillComponentResource` properties  
`collision_mask: int` > Used by `SkillComponent` when attempting to retrieve targets using the `PhysicsServer2D`. The skill will not be able to detect anything in a layer that's not included here. For performance reasons, only the essential layers should be included. Example set: `collision_mask = J.PHYSICS_LAYER_PLAYERS + J.PHYSICS_LAYER_ITEMS`   

  `valid_entities: Array[ENTITY_TYPES]` > `ENTITY_TYPES` is an enum that mirrors `J.ENTITY_TYPE` and acts as an identifier for the kind of entity that the `SkillComponentResource` can affect. Entities that do not fall into any of these types will be filtered out of the valid targets if detected. Example set: `valid_entities = [ENTITY_TYPES.ENEMY, ENTITY_TYPES.NPC]`

`hitbox_shape: PackedVector2Array` > Contains the points to make a polygon to use as a shape for collisions. If only one point is defined, the shape will be a circle, using the single Vector2's length as the radius. Setting 2 points is currently unsupported, but is planned to perform a raycast from point 0 to point 1. Example set (triangle): `hitbox_shape = [Vector2(-10,-5),Vector2(10,-5),Vector2(0,10)]`  

`hitbox_rotate_shape: bool` > This simply makes the shape defined in `hitbox_shape` be rotated to where the character is aiming at, useful for making cones that project away from the player.   
  
`cast_on_select: bool` > Makes it so when the skill is selected, it is instantly used at the player's current position and then deselected during the same frame. For skills that do not need targeting, like "HealSelf"
