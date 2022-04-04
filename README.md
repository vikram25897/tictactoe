# TicTacToe Game with LiveView

To start your Game server:

  * Make sure [`asdf`](https://github.com/asdf-vm/asdf) is installed in your system
  * Open terminal in root project directory
  * Run <code>chmod +x ./run-server.sh</code>
  * Run <code>./run-server.sh</code> and let it complete the setup

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to play game.

## Notes
* Leave `Lobby ID` field on [homepage](http://localhost:4000) empty to create a new lobby.
* In different browser tab, enter the `Lobby ID` displayed in previous tab to join as new user.
* Any user that joins after first 2 user's can only spectate.
* Spectators can't rejoin a game.
* Go to [/admin](http://localhost:4000/admin) to access Admin Dashboard.

### What can be improved?
* Authentication will help users resume playing without having to keep the game link handy.
* Admin Dashboard can display more data if needed.
* Many more tests are required which couldn't be done due to lack of time.
* UI will make you feel like playing TicTacToe with paper and pen is better.
* Can be scaled horizontally.
* GameState can be preserved across restarts if needed.

***
## Screenshots

![Player 1 Home Page](/screenshots/home_page.png)
![Player 2 Home Page](/screenshots/home_page_user_2.png)
![Player 1 Lobby Page](/screenshots/lobby_page.png)
![Player 2 Lobby Page](/screenshots/lobby_page_user_2.png)
![Player 1 Home Page With Player 2](/screenshots/lobby_page_user_1_2.png)
![Your Turn](/screenshots/game_page_your_turn.png)
![Lobby Page With Winner](/screenshots/winner_page_user_1.png)
![Spectator Home Page](/screenshots/home_page_spectator.png)
![Spectator Game Page](/screenshots/game_page_spectator.png)
![Admin Page](/screenshots/admin_page.png)

