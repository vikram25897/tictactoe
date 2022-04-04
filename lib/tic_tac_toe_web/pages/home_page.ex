defmodule TicTacToeWeb.Pages.HomePage do
  use TicTacToeWeb, :live_view
  alias __MODULE__.LobbyInfo

  alias Surface.Components.Form

  alias Form.{
    ErrorTag,
    Field,
    TextInput
  }

  data(changeset, :changeset)
  data(button_text, :string, default: "Create Lobby")

  def mount(_, _, socket) do
    {:ok, socket |> assign(changeset: LobbyInfo.changeset())}
  end

  def handle_event("change", %{"lobby_info" => lobby_info}, socket) do
    socket =
      if lobby_info["lobby_id"] |> String.trim() != "" do
        socket |> assign(button_text: "Join Lobby")
      else
        socket |> assign(button_text: "Create Lobby")
      end

    changeset =
      lobby_info
      |> LobbyInfo.changeset()
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  def handle_event("submit", %{"lobby_info" => lobby_info}, socket) do
    with {:ok, lobby_info} <- LobbyInfo.create(lobby_info),
         {:ok, lobby_id} <- LobbyInfo.get_lobby_id(lobby_info),
         {:ok, player} <-
           TicTacToe.Player.create(%{
             name: lobby_info.name,
             character: if(lobby_info.type == :new, do: Enum.random(["x", "o"]), else: nil)
           }),
         {:ok, _} <- create_or_start_game(lobby_id, lobby_info, player) do
      {:noreply,
       socket
       |> push_redirect(
         to: Routes.live_path(socket, TicTacToeWeb.Pages.GamePage, lobby_id, player.id)
       )}
    else
      {:error, %Ecto.Changeset{errors: [{term, {error, _}}]}} ->
        put_flash(socket, :error, "#{term} #{error}")

      :ignore ->
        put_flash(socket, :error, "This Game Already Exists")
    end
  end

  defp create_or_start_game(lobby_id, lobby_info, player) do
    if lobby_info.type == :new do
      TicTacToe.GameSupervisor.start_game(lobby_id, player)
    else
      TicTacToe.GameServer.join_game(lobby_id, player)
    end
  end
end
