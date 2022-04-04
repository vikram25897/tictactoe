defmodule TicTacToe.GameSupervisor do
  use DynamicSupervisor

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec start_game(String.t(), TicTacToe.Player.t()) :: :ignore | {:ok, pid}
  def start_game(lobby_id, lobby_leader) do
    case DynamicSupervisor.start_child(
           __MODULE__,
           {TicTacToe.GameServer, %{lobby_id: lobby_id, lobby_leader: lobby_leader}}
         ) do
      {:ok, pid} ->
        Phoenix.PubSub.broadcast(TicTacToe.PubSub, "games_tracker", :game_count_update)
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end
end
