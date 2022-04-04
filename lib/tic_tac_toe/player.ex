defmodule TicTacToe.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :character, :string
  end

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          character: String.t()
        }

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, ~w(name character)a)
    |> validate_required(~w(name)a)
    |> validate_inclusion(:character, ["x", "o"])
    |> autogen_id()
  end

  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  defp autogen_id(changeset) do
    case get_field(changeset, :id) do
      nil -> put_change(changeset, :id, Ecto.UUID.generate())
      _ -> changeset
    end
  end
end
