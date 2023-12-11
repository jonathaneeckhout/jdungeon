# Server-Client Synchronization  

## Overview  
As you'd expect from an MMO, JDungeon uses a typical server autorithy to actually run the game, with clients merely being intended to provide input for their characters.  
Most if not all mechanics that require networking are handled by a Component system with each of these being a node, each of these Component nodes exist both in the server and the client, and said nodes are in charge of communicating from either end to it's counterpart in the server/client.    
Unlike an usual server-client architecture however, there's no separate executable for these, all code is included in the same export and one simply selects the mode in which the game will run during startup.    


## Gateway  
An additional Gateway mode is available besides Server and Client. This is required to run the game and it takes care of transferring players between worlds and servers for scalability reasons. This means that when testing, you need to set Godot to run 3 instances at a time.

## `SyncRPC` class.  
This node exists in the `G` singleton as `G.sync_rpcs`. It contains all the RPCs that nodes use to sync with each other. Only functions in this node's script should be RPC-capable.    
Each of these RPCs are meant to be called by either the client or the server, but not both. You can easily identify which are which from their RPC settings:

Called from client, runs on server (has `any_peer`):
`@rpc("call_remote", "any_peer", "reliable")`   

Called from server, runs on client (has `autorithy`):  
`@rpc("call_remote", "authority", "unreliable")`  

You may also note that argument names for these functions are a single letter. This is intentional due to Godot needing to send argument names when performing RPCs.

## Synchronizing
All player-called RPCs are purely to request a synchronization attempt from the server. While the server's is in charge of updating both client and server side Components.  
Components use a `to_json()` method to generate a Dictionary to send over the network which the client/server counterpart can apply using it's `from_json(json_data: Dictionary)` method

**Visual example:**  
![SynchronizationFlow drawio](https://github.com/NancokPS2/jdungeon/assets/55665720/c8f94926-4ce2-42a9-8a9f-f233aee53250)
