defmodule TicTacToe.Factory do
  use ExMachina

  def winning_board_sequence,
    do:
      Enum.random([
        ["x", "x", "x", nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, "x", "x", "x", nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, "x", "x", "x"],
        ["x", nil, nil, "x", nil, nil, "x", nil, nil],
        [nil, "x", nil, nil, "x", nil, nil, "x", nil],
        [nil, nil, "x", nil, nil, "x", nil, nil, "x"],
        ["x", nil, nil, nil, "x", nil, nil, nil, "x"],
        [nil, nil, "x", nil, "x", nil, "x", nil, nil]
      ])

  def player_factory do
    %TicTacToe.Player{
      name: Faker.Person.name(),
      id: Faker.UUID.v4(),
      character: Enum.random(["x", "o"])
    }
  end

  def game_state_factory do
    leader = build(:player)

    %TicTacToe.GameState{
      lobby_id: TicTacToe.LobbyIdServer.generate_id(),
      players: [leader, build(:player)],
      lobby_leader: leader,
      spectators: [],
      status: :waiting,
      turn: nil,
      board: Stream.repeatedly(fn -> Enum.random(["x", "o", nil, nil, nil]) end) |> Enum.take(9)
    }
  end

  def winning_game_state_factory do
    player = build(:player, character: "x")

    %TicTacToe.GameState{
      lobby_id: TicTacToe.LobbyIdServer.generate_id(),
      players: [player, build(:player, character: "o")],
      lobby_leader: player,
      spectators: [],
      status: :finished,
      turn: nil,
      board: winning_board_sequence()
    }
  end
end
