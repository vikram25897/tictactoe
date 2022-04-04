defmodule TicTacToe.LobbyIdServer do
  use GenServer

  @config Hashids.new(
            alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
            # using a custom salt helps producing unique cipher text
            salt: "269292",
            # minimum length of the cipher text (1 by default)
            min_len: 3
          )

  @impl true
  def init(_) do
    {:ok, 1}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def handle_call(:generate, _, counter) do
    {:reply, Hashids.encode(@config, counter), counter + 1}
  end

  @spec generate_id :: String.t()
  def generate_id() do
    GenServer.call(__MODULE__, :generate)
  end
end
