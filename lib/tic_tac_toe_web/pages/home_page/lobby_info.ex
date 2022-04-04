defmodule TicTacToeWeb.Pages.HomePage.LobbyInfo do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias TicTacToe.GameServer

  embedded_schema do
    field :name, :string
    field :lobby_id, :string
    field :type, Ecto.Enum, values: [:new, :join], default: :new
  end

  @type t :: %LobbyInfo{
          name: nil | String.t(),
          lobby_id: nil | String.t(),
          type: :new | :join
        }

  @doc false
  def changeset(attrs \\ %{}) do
    %LobbyInfo{}
    |> cast(attrs, [:name, :lobby_id])
    |> validate_required([:name])
    |> validate_length(:name, max: 15)
    |> validate_length(:lobby_id, is: 3)
    |> uppercase_lobby_id()
    |> validate_lobby_id()
    |> lobby_type()
  end

  def uppercase_lobby_id(changeset) do
    case get_field(changeset, :lobby_id) do
      nil -> changeset
      value -> put_change(changeset, :lobby_id, String.upcase(value))
    end
  end

  def validate_lobby_id(changeset) do
    if changeset.errors[:lobby_id] do
      changeset
    else
      case get_field(changeset, :lobby_id) do
        nil ->
          changeset

        value ->
          if GameServer.game_exists?(value) do
            changeset
          else
            add_error(changeset, :lobby_id, "Lobby not found")
          end
      end
    end
  end

  @spec get_lobby_id(t()) :: {:ok, String.t()}
  def get_lobby_id(%__MODULE__{type: :new}), do: {:ok, TicTacToe.LobbyIdServer.generate_id()}
  def get_lobby_id(%__MODULE__{type: :join, lobby_id: lobby_id}), do: {:ok, lobby_id}

  @spec lobby_type(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def lobby_type(changeset) do
    case get_field(changeset, :lobby_id) do
      nil ->
        put_change(changeset, :type, :new)

      _lobby_id ->
        put_change(changeset, :type, :join)
    end
  end

  @spec create(params :: map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params
    |> changeset()
    |> apply_action(:insert)
  end
end
