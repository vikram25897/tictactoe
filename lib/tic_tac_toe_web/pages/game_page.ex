defmodule TicTacToeWeb.Pages.GamePage do
  use TicTacToeWeb, :live_view

  alias TicTacToe.GameServer
  alias TicTacToe.GameState
  alias Phoenix.PubSub
  alias TicTacToeWeb.Presence

  data lobby_id, :string
  data game_state, :any
  data player, :any
  data spectator?, :boolean, default: false

  def mount(%{"lobby_id" => lobby_id, "player_id" => player_id}, _, socket) do
    if GameServer.game_exists?(lobby_id) do
      if connected?(socket) do
        PubSub.subscribe(TicTacToe.PubSub, "lobby:#{lobby_id}")
      end

      game_state = %GameState{} = GameServer.get_game_state(lobby_id)

      socket =
        case GameState.find_player_or_spectator(game_state, player_id) do
          nil ->
            socket
            |> put_flash(:error, "Not allowed in lobby")
            |> push_redirect(to: Routes.live_path(socket, TicTacToeWeb.Pages.HomePage))

          {:player, player} ->
            socket
            |> assign(
              game_state: game_state,
              player: player,
              lobby_id: lobby_id
            )

          {:spectator, player} ->
            if connected?(socket) do
              Presence.track(
                self(),
                "spectators",
                player.id,
                %{lobby_id: lobby_id}
              )
            end

            socket
            |> assign(
              game_state: game_state,
              player: player,
              lobby_id: lobby_id,
              spectator?: true
            )
        end

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "game not found")
       |> push_redirect(to: Routes.live_path(socket, TicTacToeWeb.Pages.HomePage))}
    end
  end

  def handle_info({:game_state, game_state}, socket) do
    socket =
      if game_state.status == :draw do
        socket |> assign(game_state: game_state) |> put_flash(:error, "Game Ends In a Draw")
      else
        socket |> assign(game_state: game_state) |> clear_flash()
      end

    {:noreply, socket |> assign(game_state: game_state)}
  end

  def handle_info({:game_state, game_state, winner}, socket) do
    winning_player = Enum.find(game_state.players, fn player -> player.character == winner end)

    {:noreply,
     socket
     |> assign(game_state: game_state)
     |> put_flash(:success, "#{winning_player.name} wins")}
  end

  def handle_info(:game_ended, socket) do
    socket =
      socket
      |> put_flash(
        :error,
        "Game stopped due to inactivity"
      )
      |> push_redirect(to: Routes.live_path(socket, TicTacToeWeb.Pages.HomePage))

    {:noreply, socket}
  end

  def handle_event("start-game", _, socket) do
    GameServer.start_game(socket.assigns.lobby_id)
    {:noreply, socket}
  end

  def handle_event("restart-game", _, socket) do
    GameServer.restart_game(socket.assigns.lobby_id)
    {:noreply, socket |> clear_flash()}
  end

  def handle_event("move", %{"position" => position}, socket) do
    assigns = socket.assigns
    {position, _} = Integer.parse(position)

    if position in 0..8 do
      GameServer.move(assigns.lobby_id, assigns.player.id, position)
      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "Invalid Move")}
    end
  end
end
