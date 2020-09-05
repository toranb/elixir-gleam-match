defmodule Game.Session do
  use GenServer

  @timeout :timer.minutes(20)

  import Game.Process, only: [sleep: 1]

  def start_link(name, playing_cards, random) do
    GenServer.start_link(__MODULE__, {:ok, playing_cards, random}, name: via(name))
  end

  defp via(name), do: Game.Registry.via(name)

  @impl GenServer
  def init({:ok, playing_cards, random}) do
    state = Game.Engine.new(playing_cards, random)

    {:ok, state, @timeout}
  end

  def session_pid(name) do
    name
    |> via()
    |> GenServer.whereis()
  end

  def game_state(name) do
    GenServer.call(via(name), {:game_state})
  end

  def flip(name, flip_id) do
    GenServer.call(via(name), {:flip, flip_id})
  end

  def unflip(name) do
    sleep(10)
    GenServer.call(via(name), {:unflip})
  end

  def prepare_restart(name) do
    GenServer.call(via(name), {:prepare_restart})
  end

  def restart(name) do
    sleep(1)
    GenServer.call(via(name), {:restart})
  end

  @impl GenServer
  def handle_call({:game_state}, _from, state) do
    {:reply, state, state, @timeout}
  end

  @impl GenServer
  def handle_call({:flip, flip_id}, _from, state) do
    new_state = Game.Engine.flip(state, flip_id)
    {:reply, new_state, new_state, @timeout}
  end

  @impl GenServer
  def handle_call({:unflip}, _from, state) do
    new_state = Game.Engine.unflip(state)
    {:reply, new_state, new_state, @timeout}
  end

  @impl GenServer
  def handle_call({:prepare_restart}, _from, state) do
    new_state = Game.Engine.prepare_restart(state)
    {:reply, new_state, new_state, @timeout}
  end

  @impl GenServer
  def handle_call({:restart}, _from, state) do
    new_state = Game.Engine.restart(state)
    {:reply, new_state, new_state, @timeout}
  end

  @impl GenServer
  def handle_info(:timeout, session) do
    {:stop, {:shutdown, :timeout}, session}
  end

  @impl GenServer
  def terminate(_reason, _session) do
    :ok
  end

  def session_name do
    Registry.keys(Game.Registry, self()) |> List.first()
  end
end
