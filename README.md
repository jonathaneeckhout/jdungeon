# JDungeon

**JDungeon** is a free-to-play, open-source Massively Online Role-Playing Game (MORPG) set in a medieval fantasy world. With its top-down 2D perspective, it offers an immersive gaming experience. JDungeon is built on the principles of community-driven development, accessibility, and inclusivity.

## Overview

To get started with JDungeon, follow these steps:
1. [List of Features](#list-of-features)
2. [Feature Roadmap](#feature-roadmap)
3. [Install Instructions](#install-instructions)
4. [Contributor Guide](#contributing)

## List of Features

- Gameplay
  - Enemy System
  - NPC System
    - Vendor NPCs
  - Loot Drops upon Defeating Enemies
  - Bag system
  - Equipment system
- User Management
  - Account Creation
  - Login System
- AI
  - Wander
  - Wander and Flee When Attacked
- Networking
  - Synchronization of Entities (Players, Enemies, NPCs, Items, etc.)
  - Synchronization of Movement/Velocity 
  - Synchronization of Damage
  - Synchronization of Attacks on Targets
  - Synchronization of Entities Deaths
  - Synchronization of Equipment
  - Synchronization of Bag
- AI
  - Wander Behavior
- Content
  - World map

## Feature Roadmap
- Gameplay
  - Integrate Player Leveling System
- Networking
  - Synchronize Stats
- AI
  - Add Wandering and Attacking Behavior
- Chat
  - Integrate Chat Panel
  - Establish General Chat Functionality
  - Implement Whisper Chat Capability
- Content
  - Create world map
  - Create more enemies
  - Create stats that make sense

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


## Support and Community

Join our [Community Discord](https://discord.gg/upjkY2ZZ) to connect with other players and developers, seek assistance, and stay updated on the latest developments.

## License

JDungeon is licensed under the [BSD 2-Clause License](LICENSE).

---

Thank you for choosing JDungeon. We look forward to your adventures in our medieval fantasy world!
