defmodule TicTacToe.GameStateTest do
  use ExUnit.Case
  import TicTacToe.Factory

  alias TicTacToe.{
    GameState,
    Player
  }

  @valid_lobby_id "XYZ"

  test "create/1 returns game_struct" do
    player = Player.create(%{name: "Name"})
    assert %GameState{} = game_state = GameState.create_game(@valid_lobby_id, player)
    assert game_state.board == List.duplicate(nil, 9)
    assert game_state.lobby_id == @valid_lobby_id
    assert game_state.players == [player]
    assert game_state.spectators == []
    assert game_state.turn == nil
    assert game_state.status == :waiting
  end

  describe "add_player_or_spectator/2" do
    test "joins as player" do
      leader = build(:player, character: "o")
      game_state = build(:game_state, lobby_leader: leader, players: [leader])
      player = build(:player, character: nil)

      assert {:joined_as_player, game_state} =
               GameState.add_player_or_spectator(game_state, player)

      assert length(game_state.players) == 2
      assert [_, %Player{character: "x"}] = game_state.players
    end

    test "joins as spectator" do
      game_state = build(:game_state)
      player = build(:player, character: nil)

      assert {:joined_as_spectator, game_state} =
               GameState.add_player_or_spectator(game_state, player)

      assert [^player] = game_state.spectators
    end

    test "error already joined" do
      game_state = build(:game_state)

      assert {:error, :already_joined} =
               GameState.add_player_or_spectator(game_state, game_state.lobby_leader)
    end
  end

  describe "start_game/1" do
    test "succesful with enough players" do
      game_state = build(:game_state)
      assert game_state.status == :waiting
      assert {:ok, game_state} = GameState.start_game(game_state)
      assert game_state.status == :playing
    end

    test "error when not enough players" do
      leader = build(:player)
      game_state = build(:game_state, lobby_leader: leader, players: [leader])
      assert game_state.status == :waiting
      assert {:error, :not_enough_players} = GameState.start_game(game_state)
    end
  end

  test "restart_game/1" do
    game_state = build(:winning_game_state)
    assert game_state.status == :finished
    assert %GameState{} = game_state = GameState.restart_game(game_state)
    assert game_state.status == :playing
    assert game_state.board == List.duplicate(nil, 9)
  end

  test "remove_spectator/1" do
    spectator = build(:player)
    game_state = build(:game_state, spectators: [spectator])
    assert length(game_state.spectators) == 1
    assert %GameState{} = game_state = GameState.remove_spectator(game_state, spectator.id)
    assert length(game_state.spectators) == 0
  end

  describe "find_player_or_spectator/2" do
    setup do
      %GameState{players: [player, _], spectators: [spectator]} =
        game_state = build(:game_state, spectators: [build(:player)])

      {:ok, game_state: game_state, player: player, spectator: spectator}
    end

    test "finds player", %{game_state: game_state, player: player} do
      assert {:player, ^player} = GameState.find_player_or_spectator(game_state, player.id)
    end

    test "finds spectator", %{game_state: game_state, spectator: spectator} do
      assert {:spectator, ^spectator} =
               GameState.find_player_or_spectator(game_state, spectator.id)
    end

    test "finds nothing", %{game_state: game_state} do
      assert nil == GameState.find_player_or_spectator(game_state, Ecto.UUID.generate())
    end
  end

  describe "check_winner/1" do
    test "finds winner" do
      game_state = build(:winning_game_state)
      assert "x" == GameState.check_winner(game_state)
    end

    test "no winner found" do
      game_state = build(:game_state, board: ["o", "x", "o", "x", "x", "o", "x", "o", "x"])
      assert nil == GameState.check_winner(game_state)
    end
  end

  describe "move/3" do
    setup do
      player = build(:player, character: "x")

      game_state =
        build(:game_state,
          status: :playing,
          turn: "x",
          status: :playing,
          lobby_leader: player,
          players: [player, build(:player, character: "o")]
        )

      {:ok, game_state: game_state, player: player}
    end

    test "moves", %{game_state: game_state, player: player} do
      game_state = %GameState{game_state | board: ["o", "x", "o", nil, nil, "o", "x", "o", "x"]}
      valid_position = Enum.find_index(game_state.board, fn sq -> sq == nil end)
      assert {:ok, _game_state, nil} = GameState.move(game_state, player.id, valid_position)
    end

    test "move ends with draw", %{game_state: game_state, player: player} do
      game_state = %GameState{game_state | board: ["o", "x", "o", nil, "x", "o", "x", "o", "x"]}
      assert {:ok, game_state, nil} = GameState.move(game_state, player.id, 3)
      assert game_state.status == :draw
    end

    test "move ends with winner", %{game_state: game_state, player: player} do
      game_state = %GameState{game_state | board: ["x", "x", nil, "o", "o", nil, nil, nil, nil]}
      assert {:ok, game_state, "x"} = GameState.move(game_state, player.id, 2)
      assert game_state.status == :finished
    end

    test "not player turn", %{game_state: game_state, player: player} do
      game_state = %GameState{game_state | turn: "o"}
      valid_position = Enum.find_index(game_state.board, fn sq -> sq == nil end)
      assert {:error, :not_player_turn} = GameState.move(game_state, player.id, valid_position)
    end

    test "invalid move", %{game_state: game_state, player: player} do
      valid_position = Enum.find_index(game_state.board, fn sq -> sq != nil end)
      assert {:error, :invalid_move} = GameState.move(game_state, player.id, valid_position)
    end

    test "player not found", %{game_state: game_state} do
      assert {:error, :player_not_found} = GameState.move(game_state, Ecto.UUID.generate(), 1)
    end
  end
end
