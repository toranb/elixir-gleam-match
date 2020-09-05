defmodule Game.Engine do
  defstruct cards: [], winner: false, animating: false, playing_cards: [], random: nil, score: nil

  alias Game.Card
  alias Game.Hash

  def new(playing_cards, random) do
    cards =
      playing_cards
      |> generate_cards(random)

    %__MODULE__{cards: cards, playing_cards: playing_cards, random: random, score: 0}
  end

  def unflip(%__MODULE__{cards: cards} = struct) do
    new_cards =
      cards
      |> Enum.map(fn card -> %Card{card | flipped: false} end)

    %{struct | cards: new_cards, animating: false}
  end

  def flip(%__MODULE__{cards: cards, animating: animating, winner: winner} = struct, flip_id) do
    if animating == true or winner == true do
      struct
    else
      cards
      |> Enum.map(&flip_card(&1, flip_id))
      |> attempt_match(struct)
      |> declare_winner()
    end
  end

  def attempt_match(cards, struct) do
    flipped_cards = Enum.filter(cards, fn card -> card.flipped end)

    case Enum.count(flipped_cards) == 2 do
      true ->
        [
          %Card{:name => first},
          %Card{:name => last}
        ] = flipped_cards

        case first === last do
          true ->
            %__MODULE__{struct | cards: Enum.map(cards, &pair_card(&1))}

          false ->
            %__MODULE__{struct | cards: cards, animating: true}
        end

      false ->
        %__MODULE__{struct | cards: cards}
    end
  end

  def declare_winner(%__MODULE__{cards: cards} = struct) do
    total = Enum.count(cards)
    paired = Enum.count(cards, fn card -> card.paired == true end)

    case total == paired do
      true ->
        %__MODULE__{struct | winner: true}

      false ->
        %__MODULE__{struct | winner: false}
    end
  end

  def pair_card(%Card{flipped: flipped} = card) do
    case flipped == true do
      true -> %Card{card | paired: true, flipped: false}
      false -> card
    end
  end

  def flip_card(%Card{id: id} = card, flip_id) do
    case id == flip_id do
      true -> %Card{card | flipped: true}
      false -> card
    end
  end

  def prepare_restart(%__MODULE__{winner: winner, cards: cards} = struct) do
    case winner != nil do
      true ->
        unpaired =
          cards
          |> Enum.map(fn card -> %Card{card | paired: false} end)

        %__MODULE__{struct | cards: unpaired}

      false ->
        struct
    end
  end

  def restart(%__MODULE__{playing_cards: playing_cards, random: random}) do
    __MODULE__.new(playing_cards, random)
  end

  def generate_cards(cards, random) do
    length = 6
    total = Enum.count(cards)

    Enum.map(cards, fn name ->
      hash = Hash.hmac("type:card", name, length)
      one = %Card{id: "#{hash}1", name: name, image: "/images/cards/#{name}.png"}
      two = %Card{id: "#{hash}2", name: name, image: "/images/cards/#{name}.png"}
      [one, two]
    end)
    |> List.flatten()
    |> random.take_random(total * 2)
  end
end
