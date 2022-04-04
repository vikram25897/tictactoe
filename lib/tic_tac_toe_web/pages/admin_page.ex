defmodule TicTacToeWeb.Pages.AdminPage do
  use TicTacToeWeb, :live_view

  alias Phoenix.PubSub
  alias TicTacToeWeb.Presence

  data games_count, :integer
  data spectator_count, :integer

  def mount(_, _, socket) do
    if connected?(socket) do
      PubSub.subscribe(TicTacToe.PubSub, "spectators")
      PubSub.subscribe(TicTacToe.PubSub, "games_tracker")
    end

    %{active: games_count} = DynamicSupervisor.count_children(TicTacToe.GameSupervisor)
    spectator_count = "spectators" |> Presence.list() |> map_size()

    {:ok,
     socket
     |> assign(
       games_count: games_count,
       spectator_count: spectator_count
     )}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{spectator_count: count}} = socket
      ) do
    spectator_count = count + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :spectator_count, spectator_count)}
  end

  def handle_info(:game_count_update, socket) do
    %{active: games_count} = DynamicSupervisor.count_children(TicTacToe.GameSupervisor)
    {:noreply, socket |> assign(games_count: games_count)}
  end
end
