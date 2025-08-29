## Collabyrinth: A multiplayer maze exploration game built in Godot 4

Collabyrinth is a multiplayer maze exporation game focusing on collaboration to escape a randomly generated maze.
It is a two player game (Though in future, more players may be added) where each player can only see in one cartesian direction.
Each maze is represented by a 2D array of cells, where each cell can be of type wall, air, entrance, or exit.
Both players control one character, who takes up one cell of the maze. Player one can only see the cells in the row that the character is in, while player Two can only see the cells in the column.
Additionally, player 1 can only move left and right, while player two can only move up and down.
As players move, the rows and columns shift, so that both players can see correctly according to where the character is.
The players should not be able to see each other's game. As a result, they are required to communicate with each other to navigate and escape the maze.

In the image below, the left side shows player 1's view, while the right side shows player 2's view.

![Gameplay Screenshot](./PromoImages/Ingame.png)

Player 1 is not able to move, since he is encased in walls. He has to communicate with Player 2 to move up or down.

Here, Player 1 can see the exit on his left.

![Gameplay Screenshot](./PromoImages/ExitVisible.png)

This time, Player 2 can't move, but if Player 1 moves 3 spaces left, the they've escaped the maze.
When the team escapes the maze, the host is prompted to start a new game.

The game currently only supports Local multiplayer over a Lan network, using an auto-generated code.

![Gameplay Screenshot](./PromoImages/MulitplayerMenu.png)

Here, you can also see that the host is able to decide which axis each player views. If he so chooses, he can swap it, so that he sees the column and player 2 sees the row.
He is also able to decide the radius of the maze (how big the maze will be) and the view radius (how many cells in each direction the player can see.)

Here, also, is the main menu. 

![Gameplay Screenshot](./PromoImages/TitleScreen.png)

Currently, the Solo button doesn't do anything, as a single player mode doesn't exist yet.

Clicking Collab will take you to the multiplayer setup screen shown in the previous image.

This game was made as a learning opportunity, so it may stay complete here, but there are a few ideas a may add or would have liked to add:
- Cleaner UI
- Online multiplayer
- Enemies
    - I am madly entertained by the idea of players have to communicate to escape a fast-approaching enemy.
- Puzzle elements
    - Keys and doors, tools that the player can obtain, etc
- Multiple "perspectives"
    - Each player will see a different world. As of right now, all players see a UFO in space, though what if Player 2 saw a submarine in the ocean?
- A story mode
    - I have an idea for a narrative that could tell a cute story about the game. This would have to tie into the perspectives mentioned above. It would also act as a tutorial for any new puzzle elements and such
- Cross platform
    - The graphics are low demand, so being able to play on mobile could make Collabyrinth a fun party game.
- A single player mode.
    - Perhaps alongisde an "AI companion," or just a basic maze solving game where the player can see in both dimensions
- 3+ players
    - But 3D and 4D mazes can get pretty complex, so for now, 2 players will do.
- Different maze generator parameter
    - Right now the generator uses prims algorithm.




