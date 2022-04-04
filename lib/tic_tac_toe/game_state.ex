defmodule TicTacToe.GameState do
  alias TicTacToe.Player

  defstruct lobby_id: nil,
            players: [],
            lobby_leader: nil,
            spectators: [],
            turn: nil,
            status: :waiting,
            board: List.duplicate(nil, 9)

  @type t :: %__MODULE__{
          lobby_id: nil | String.t(),
          players: [Player.t()],
          lobby_leader: nil | Player.t(),
          spectators: [Player.t()],
          turn: nil | String.t(),
          status: :waiting | :playing | :draw | :finished,
          board: [atom()]
        }

  @turn_map %{
    "x" => "o",
    "o" => "x"
  }

  @spec create_game(lobby_id :: String.t(), lobby_leader :: Player.t()) :: t()
  def create_game(lobby_id, lobby_leader) do
    %__MODULE__{
      lobby_id: lobby_id,
      players: [lobby_leader],
      lobby_leader: lobby_leader
    }
  end

  @spec add_player_or_spectator(t(), Player.t()) ::
          {:joined_as_player | :joined_as_spectator, t()} | {:error, :already_joined}
  def add_player_or_spectator(%__MODULE__{} = game_state, %Player{} = player) do
    all_players = game_state.players ++ game_state.spectators

    if Enum.member?(all_players, player) do
      {:error, :already_joined}
    else
      if length(game_state.players) < 2 do
        player = %Player{
          player
          | character: @turn_map[game_state.lobby_leader.character]
        }

        {:joined_as_player, %__MODULE__{game_state | players: [game_state.lobby_leader, player]}}
      else
        {:joined_as_spectator,
         %__MODULE__{game_state | spectators: game_state.spectators ++ [player]}}
      end
    end
  end

  @spec start_game(t()) :: {:ok, t()} | {:error, :not_enough_players}
  def start_game(game_state) do
    if length(game_state.players) == 2 do
      {:ok,
       %__MODULE__{
         game_state
         | status: :playing,
           turn: Enum.random(["x", "o"])
       }}
    else
      {:error, :not_enough_players}
    end
  end

  @spec restart_game(t()) :: t()
  def restart_game(game_state) do
    %__MODULE__{
      game_state
      | status: :playing,
        turn: Enum.random(["x", "o"]),
        board: List.duplicate(nil, 9)
    }
  end

  @spec remove_spectator(t(), String.t()) :: t()
  def remove_spectator(game_state, spectator_id) do
    %{
      game_state
      | spectators: Enum.reject(game_state.spectators, fn spec -> spec.id == spectator_id end)
    }
  end

  @spec find_player_or_spectator(t(), String.t()) :: {:player | :spectator, Player.t()} | nil
  def find_player_or_spectator(game_state, player_id) do
    all = game_state.players ++ game_state.spectators

    index =
      Enum.find_index(all, fn player ->
        player.id == player_id
      end)

    cond do
      index == nil -> nil
      index < 2 -> {:player, Enum.at(all, index)}
      true -> {:spectator, Enum.at(all, index)}
    end
  end

  @spec check_winner(t()) :: nil | atom()
  def check_winner(%__MODULE__{board: board}) do
    for c <- ["x", "o"] do
      case board do
        [^c, ^c, ^c, _, _, _, _, _, _] -> c
        [_, _, _, ^c, ^c, ^c, _, _, _] -> c
        [_, _, _, _, _, _, ^c, ^c, ^c] -> c
        [^c, _, _, ^c, _, _, ^c, _, _] -> c
        [_, ^c, _, _, ^c, _, _, ^c, _] -> c
        [_, _, ^c, _, _, ^c, _, _, ^c] -> c
        [^c, _, _, _, ^c, _, _, _, ^c] -> c
        [_, _, ^c, _, ^c, _, ^c, _, _] -> c
        _ -> nil
      end
    end
    |> Enum.find(fn r -> r != nil end)
  end

  @spec move(t(), String.t(), integer()) :: {:ok, t(), atom()} | {:error, term()}
  def move(%__MODULE__{board: board} = game_state, player_id, position) do
    with {:ok, player} <- is_player_turn?(game_state, player_id),
         true <- is_valid_move?(board, position) do
      game_state = %{
        game_state
        | board: List.update_at(board, position, fn _ -> player.character end),
          turn: @turn_map[player.character]
      }

      winner = check_winner(game_state)

      game_state =
        if game_state.board |> Enum.filter(fn sq -> sq != nil end) |> length() == 9 and
             winner == nil do
          %{game_state | status: :draw}
        else
          if winner != nil do
            %{game_state | status: :finished}
          else
            game_state
          end
        end

      {:ok, game_state, check_winner(game_state)}
    else
      false -> {:error, :invalid_move}
      err -> err
    end
  end

  defp is_player_turn?(%__MODULE__{players: players, turn: turn}, player_id) do
    case Enum.find(players, fn player -> player.id == player_id end) do
      %Player{character: ^turn} = player -> {:ok, player}
      %Player{} -> {:error, :not_player_turn}
      nil -> {:error, :player_not_found}
    end
  end

  defp is_valid_move?(board, position) do
    Enum.at(board, position) == nil
  end
end
