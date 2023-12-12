[![build latest jdungeon](https://github.com/jonathaneeckhout/jdungeon/actions/workflows/build-artifacts-and-push-docker-image.yml/badge.svg)](https://github.com/jonathaneeckhout/jdungeon/actions/workflows/build-artifacts-and-push-docker-image.yml)
[![](https://dcbadge.vercel.app/api/server/KGwTyXumdv?style=flat)](https://discord.gg/KGwTyXumdv)


# JDungeon

**JDungeon** is a free-to-play, open-source Massively Online Role-Playing Game (MORPG) set in a medieval fantasy world. With its top-down 2D perspective, it offers an immersive gaming experience. JDungeon is built on the principles of community-driven development, accessibility, and inclusivity.

## Overview

To get started with JDungeon, follow these steps:
1. [Lore](#lore)
2. [Screenshots](#screenshots)
3. [Videos](#videos)
4. [List of Features](#list-of-features)
5. [Feature Roadmap](#feature-roadmap)
6. [Feature Requests](#feature-requests)
7. [Install Instructions](#install-instructions)
8. [Contributor Guide](#contributing)

## Lore
Centuries ago the world was whole. The kingdoms were diverse, numerous, and fruitful. The world enjoyed relative peace barring the occasional border conflict. Not much is known anymore of this bright past. The histories are as fragmented as the world itself, each Shard possessing a modicum of knowledge. We don't know what happened. We don't know why. We don't know who. All we know is that the Shards drift further and faster every year. The land itself is not gone. There's no magic that can do that. But to move it? To encourage the very foundation of the earth to shift and set sail? Well, apparently that is possible. In the past there were several Rooted Shards. The last vestiges of normalcy. You could charter transport between them. The magnetic poles of each Root were set and were navigable. They didn't just blip in and out of existence. The Shard would not be persuaded. It liked where it was and it would damn well remain there. But just as water chisels away at the earth, so does time carve away bits of the soul. Now all that's left is...us. Formerly South Radix, now just Radix. You can't be "South" if there's nothing to be South of eh?

## Screenshots
![preview_3](https://github.com/jonathaneeckhout/jdungeon/assets/44840503/80d47030-02fa-4c10-b3fc-68b85e2c4673)
![preview_2](https://github.com/jonathaneeckhout/jdungeon/assets/44840503/164aef2b-56df-4c04-add3-9312cde66db7)
![preview_1](https://github.com/jonathaneeckhout/jdungeon/assets/44840503/ec5ce150-82d2-4176-8af1-c32586c88400)

## Videos
### How to open and run the Godot project
[![Watch the video](https://img.youtube.com/vi/p-54V3rKuaQ/maxresdefault.jpg)](https://youtu.be/p-54V3rKuaQ)

### How to run the online deployed game
[![Watch the video](https://img.youtube.com/vi/45mzdgq25eE/maxresdefault.jpg)](https://youtu.be/45mzdgq25eE?si=AypC6xL_UiPwCAEU)

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
  - Portal from one chunk to another
- AI
  - Wander behavior
  - Attack and flee behavior
- Content
  - World map
- UI
  - Game menu to quit the game
  - Rebind keys menu
  - Configure settings menu
  - Unstuck menu
  - Report bug menu
  - A check if the current version of your client matches the version of the deployed client (only for deployed instances)

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
### Step 4: Set you Godot editor to run 3 instances
By default Godot will only run 1 instance of the game. For this game you will need to at least run 1 client instance, 1 gateway instance and 1 server instance.
You can achieve this by going to the "Debug" menu on the top left corner in the Godot editor and click on the "Run Multiple Instances" menu and select the "Run 3 Instances" or more option.

### Step 5: Run the project
Now you can run the project.
Select in 1 instance the gateway server option, next a server option and the other the client option.
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
