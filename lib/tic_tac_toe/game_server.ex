defmodule TicTacToe.GameServer do
  use GenServer

  alias TicTacToe.{
    GameState,
    Player
  }

  @timeout 300 * 1000

  @impl true
  @spec init(%{:lobby_id => binary, :lobby_leader => TicTacToe.Player.t(), optional(any) => any}) ::
          {:ok, {TicTacToe.GameState.t(), integer()}}
  def init(%{lobby_id: lobby_id, lobby_leader: lobby_leader}) do
    Phoenix.PubSub.subscribe(TicTacToe.PubSub, "spectators")
    Process.send_after(self(), :check_inactivity, 5000)
    {:ok, {GameState.create_game(lobby_id, lobby_leader), @timeout}}
  end

  def start_link(%{lobby_id: lobby_id, lobby_leader: _lobby_leader} = init_args) do
    GenServer.start_link(__MODULE__, init_args, name: {:global, lobby_id})
  end

  @spec join_game(String.t(), Player.t()) ::
          {:ok, :joined_as_player | :joined_as_spectator}
          | {:error, :already_joined | :lobby_not_found}
  def join_game(lobby_id, player) do
    GenServer.call({:global, lobby_id}, {:join, player})
  end

  @spec move(String.t(), String.t(), integer()) :: GameState.t()
  def move(lobby_id, player_id, position) do
    GenServer.call({:global, lobby_id}, {:move, player_id, position})
  end

  @spec get_game_state(String.t()) :: GameState.t()
  def get_game_state(lobby_id) do
    GenServer.call({:global, lobby_id}, :get_game_state)
  end

  @spec start_game(String.t()) :: GameState.t()
  def start_game(lobby_id) do
    GenServer.call({:global, lobby_id}, :start_game)
  end

  @spec restart_game(String.t()) :: GameState.t()
  def restart_game(lobby_id) do
    GenServer.call({:global, lobby_id}, :restart_game)
  end

  @spec remove_spectator(String.t(), String.t()) :: GameState.t()
  def remove_spectator(lobby_id, spectator_id) do
    GenServer.call({:global, lobby_id}, {:remove_spectator, spectator_id})
  end

  @impl true
  def handle_call({:join, player}, _from, {state, _}) do
    case GameState.add_player_or_spectator(state, player) do
      {:joined_as_player, game_state} ->
        broadcast_game_state(game_state)
        {:reply, {:ok, :joined_as_player}, {game_state, @timeout}}

      {:joined_as_spectator, game_state} ->
        broadcast_game_state(game_state)
        {:reply, {:ok, :joined_as_spectator}, {game_state, @timeout}}

      {:error, :already_joined} ->
        {:reply, {:error, :already_joined}, {state, @timeout}}
    end
  end

  @impl true
  def handle_call({:move, player_id, position}, _from, {state, _}) do
    case GameState.move(state, player_id, position) do
      {:ok, game_state, winner} ->
        if winner != nil do
          broadcast_game_state(game_state, winner)
        else
          broadcast_game_state(game_state)
        end

        {:reply, game_state, {game_state, @timeout}}

      err ->
        {:reply, err, {state, @timeout}}
    end
  end

  @impl true
  def handle_call(:start_game, _from, {state, _}) do
    case GameState.start_game(state) do
      {:ok, game_state} ->
        broadcast_game_state(game_state)
        {:reply, game_state, {game_state, @timeout}}

      err ->
        {:reply, err, {state, @timeout}}
    end
  end

  @impl true
  def handle_call({:remove_spectator, spectator_id}, _from, {state, _}) do
    game_state = GameState.remove_spectator(state, spectator_id)
    {:reply, game_state, {game_state, @timeout}}
  end

  @impl true
  def handle_call(:restart_game, _from, {state, _}) do
    game_state = GameState.restart_game(state)
    broadcast_game_state(game_state)
    {:reply, game_state, {game_state, @timeout}}
  end

  @impl true
  def handle_call(:get_game_state, _from, {state, _}) do
    {:reply, state, {state, @timeout}}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: _joins, leaves: leaves}},
        {%GameState{lobby_id: lobby_id} = state, _}
      ) do
    leaving_spectators =
      Enum.filter(leaves, fn
        {_, %{metas: [%{lobby_id: ^lobby_id}]}} -> true
        _ -> false
      end)
      |> Enum.map(fn {id, _} -> id end)

    game_state =
      Enum.reduce(leaving_spectators, state, fn leaving_spectator, acc ->
        GameState.remove_spectator(acc, leaving_spectator)
      end)

    {:noreply, {game_state, @timeout}}
  end

  def handle_info(:check_inactivity, {game_state, timeout}) do
    timeout = timeout - 5000

    if timeout <= 0 do
      broadcast_game_end(game_state)
      {:stop, :inactivity, {game_state, timeout}}
    else
      Process.send_after(self(), :check_inactivity, 5000)
      {:noreply, {game_state, timeout}}
    end
  end

  @spec game_exists?(String.t()) :: boolean()
  def game_exists?(lobby_id) do
    case :global.whereis_name(lobby_id) do
      :undefined -> false
      _ -> true
    end
  end

  defp broadcast_game_state(game_state) do
    Phoenix.PubSub.broadcast!(
      TicTacToe.PubSub,
      "lobby:#{game_state.lobby_id}",
      {:game_state, game_state}
    )
  end

  defp broadcast_game_state(game_state, winner) do
    Phoenix.PubSub.broadcast!(
      TicTacToe.PubSub,
      "lobby:#{game_state.lobby_id}",
      {:game_state, game_state, winner}
    )
  end

  defp broadcast_game_end(game_state) do
    Phoenix.PubSub.broadcast!(
      TicTacToe.PubSub,
      "lobby:#{game_state.lobby_id}",
      :game_ended
    )

    Phoenix.PubSub.broadcast!(TicTacToe.PubSub, "games_tracker", :game_count_update)
  end
end
