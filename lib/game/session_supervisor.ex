defmodule Game.SessionSupervisor do
  use DynamicSupervisor

  @default_playing_cards ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(name, playing_cards \\ @default_playing_cards, random \\ true) do
    child_spec = %{
      id: Game.Session,
      start: {Game.Session, :start_link, [name, playing_cards, random]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
