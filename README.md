# JDungeon

**JDungeon** is a free-to-play, open-source Massively Online Role-Playing Game (MORPG) set in a medieval fantasy world. With its top-down 2D perspective, it offers an immersive gaming experience. JDungeon is built on the principles of community-driven development, accessibility, and inclusivity.

## Overview

To get started with JDungeon, follow these steps:
1. [Lore](#lore)
2. [List of Features](#list-of-features)
3. [Feature Roadmap](#feature-roadmap)
4. [Feature Requests](#feature-requests)
5. [Install Instructions](#install-instructions)
6. [Contributor Guide](#contributing)

## Lore
Centuries ago the world was whole. The kingdoms were diverse, numerous, and fruitful. The world enjoyed relative peace barring the occasional border conflict. Not much is known anymore of this bright past. The histories are as fragmented as the world itself, each Shard possessing a modicum of knowledge. We don't know what happened. We don't know why. We don't know who. All we know is that the Shards drift further and faster every year. The land itself is not gone. There's no magic that can do that. But to move it? To encourage the very foundation of the earth to shift and set sail? Well, apparently that is possible. In the past there were several Rooted Shards. The last vestiges of normalcy. You could charter transport between them. The magnetic poles of each Root were set and were navigable. They didn't just blip in and out of existence. The Shard would not be persuaded. It liked where it was and it would damn well remain there. But just as water chisels away at the earth, so does time carve away bits of the soul. Now all that's left is...us. Formerly South Radix, now just Radix. You can't be "South" if there's nothing to be South of eh?

## List of Features

- Gameplay
  - Enemy system
  - NPC system
    - Vendor NPCs
  - Loot drops upon defeating enemies
  - Bag system
  - Equipment system
  - Players get experience upon defeating enemies
  - Player level up when reaching a certain amount of experience
- User Management
  - Account creation
  - Login system
- AI
  - Wander
  - Wander and flee when attacked
- Networking
  - Synchronization of entities (players, enemies, NPCs, items, etc.)
  - Synchronization of movement/velocity 
  - Synchronization of damage
  - Synchronization of attacks on targets
  - Synchronization of entities deaths
  - Synchronization of equipment
  - Synchronization of bag
- AI
  - Wander behavior
- Content
  - World map
- UI
  - Game menu to quit the game

## Feature Roadmap
Have a look at the current open tickets of what features are on the roadmap: https://github.com/jonathaneeckhout/jdungeon/issues 

## Feature Requests
You can submit feature requests for JDungeon by opening a new issue. To do this, make sure to start the issue title with "Feature Request:" and apply the "feature request" label. Be sure to provide comprehensive details regarding the feature, its intended purpose, what it aims to achieve or resolve, and any relevant use cases. Once submitted, your feature request will undergo a review process and, if approved, will be transformed into a development task.

## Install Instructions
### Step 1: Clone the repository
```bash
git clone https://github.com/jonathaneeckhout/jdungeon
```
### Step 2: Open the projet in Godot
Make sure to use the "Godot Engine -.NET" version of Godot.
```bash
cd jdungeon
Godot_v4.x project.godot
```
### Step 3: Make the .env file
The .env file is used to group all the environment variables used by the game.
The easiest way to get started is to just copy or rename the [.env.example](.env.example) file to a ".env" file and leave it as it is. 
You can however modify the content to your needs.
```bash
cp .env.example .env
```
### Step 4: Set you Godot editor to run 2 instances
By default Godot will only run 1 instance of the game. As this is a multiplayer game you will always need 1 server instance and 1 or more client instances. 
You can achieve this by going to the "Debug" menu on the top left corner in the Godot editor and click on the "Run Multiple Instances" menu and select the "Run 2 Instances" or more option.

### Step 5: Run the project
Now you can run the project.
Select in 1 instance the server option and the others the client option.
Make sure to first create your account before trying to login.
Enjoy!

## Contributing

We encourage contributions from the community. If you'd like to contribute to JDungeon, please follow the guidelines in our [Contribution Guide](CONTRIBUTING.md).

If you plan to contribute, have a look at the open issues on GitHub. These issues play a crucial role in helping us achieve important milestones ([current milestone we're working on](https://github.com/jonathaneeckhout/jdungeon/milestone/1)) and shape the development of JDungeon. You can find the list of open issues in our [Issues](https://github.com/jonathaneeckhout/jdungeon/issues) section.

This addition will provide potential contributors with a clear path to engage with the project by emphasizing the significance of the open issues in reaching project goals.

## Support and Community

Join our [Discord server](https://discord.gg/KGwTyXumdv) to connect with other players and developers, seek assistance, and stay updated on the latest developments.

## License

JDungeon is licensed under the [BSD 2-Clause License](LICENSE).

---

Thank you for choosing JDungeon. We look forward to your adventures in our medieval fantasy world!
