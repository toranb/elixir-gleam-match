defmodule Game.FakeRandom do
  def take_random(cards, number) do
    Enum.take(cards, number)
  end
end
