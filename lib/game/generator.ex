defmodule Game.Generator do
  def haiku do
    [
      Enum.random(foods()),
      :rand.uniform(9999)
    ]
    |> Enum.join("-")
  end

  def foods do
    ~w(
      apple banana orange
      grape kiwi mango
      pear pineapple strawberry
      tomato watermelon cantaloupe
    )
  end
end
