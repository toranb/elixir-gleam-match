defmodule Game.Engine do
  use Game.Strucord, name: :engine, from: "gen/src/game_Engine.hrl"

  def new(playing_cards, random) when is_boolean(random) do
    record = :game.init(playing_cards, random)
    from_record_custom(record)
  end

  def flip(%__MODULE__{} = struct, flip_id) when is_binary(flip_id) do
    gleamify(struct, fn record ->
      :game.flip(record, flip_id)
    end)
  end

  def unflip(%__MODULE__{} = struct) do
    gleamify(struct, fn record ->
      :game.unflip(record)
    end)
  end

  def prepare_restart(%__MODULE__{} = struct) do
    gleamify(struct, fn record ->
      :game.prepare_restart(record)
    end)
  end

  def restart(%__MODULE__{playing_cards: playing_cards, random: random}) do
    __MODULE__.new(playing_cards, random)
  end

  def gleamify(%__MODULE__{} = struct, f) when is_function(f, 1) do
    struct
    |> to_record_custom()
    |> f.()
    |> from_record_custom()
  end

  def to_record_custom(%__MODULE__{
        cards: cards,
        winner: winner,
        animating: animating,
        score: score,
        playing_cards: playing_cards,
        random: random
      }) do
    cards = Enum.map(cards, fn c -> Game.Card.to_record(c) end)

    {:engine, cards, winner, animating, score, playing_cards, random}
  end

  def from_record_custom({:engine, cards, winner, animating, score, playing_cards, random}) do
    cards = Enum.map(cards, fn c -> Game.Card.from_record(c) end)

    %__MODULE__{
      cards: cards,
      winner: winner,
      animating: animating,
      score: score,
      playing_cards: playing_cards,
      random: random
    }
  end
end
