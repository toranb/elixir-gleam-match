defmodule Game.EngineTest do
  use ExUnit.Case, async: true

  alias Game.Card
  alias Game.FakeRandom

  @playing_cards ["one", "two"]
  @image_one "/images/cards/one.png"
  @image_two "/images/cards/two.png"
  @id_one_a "24CEDF1"
  @id_one_b "24CEDF2"
  @id_two_a "3079821"
  @id_two_b "3079822"

  test "new returns game struct with list of cards" do
    state = Game.Engine.new(@playing_cards, FakeRandom)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = state

    assert winner == false
    assert animating == false
    assert Enum.count(cards) == 4

    [
      %Card{id: id_one, name: name_one, image: image_one, flipped: flipped_one},
      %Card{id: id_two, name: name_two, image: image_two, flipped: flipped_two},
      %Card{id: id_three, name: name_three, image: image_three, flipped: flipped_three},
      %Card{id: id_four, name: name_four, image: image_four, flipped: flipped_four}
    ] = cards

    assert id_one == @id_one_a
    assert image_one == @image_one
    assert name_one == "one"
    assert flipped_one == false

    assert id_two == @id_one_b
    assert image_two == @image_one
    assert name_two == "one"
    assert flipped_two == false

    assert id_three == @id_two_a
    assert image_three == @image_two
    assert name_three == "two"
    assert flipped_three == false

    assert id_four == @id_two_b
    assert image_four == @image_two
    assert name_four == "two"
    assert flipped_four == false
  end

  test "flip will mark a given card with flipped attribute" do
    state = Game.Engine.new(@playing_cards, FakeRandom)
    new_state = Game.Engine.flip(state, @id_two_a)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = new_state

    assert winner == false
    assert animating == false
    assert Enum.count(cards) == 4

    [
      %Card{flipped: flip_one},
      %Card{flipped: flip_two},
      %Card{flipped: flip_three},
      %Card{flipped: flip_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == true
    assert flip_four == false
  end

  test "flipping the 2nd card in a match will mark the cards as paired and revert flipped to false" do
    state = Game.Engine.new(@playing_cards, FakeRandom)
    new_state = Game.Engine.flip(state, @id_two_a)
    paired_state = Game.Engine.flip(new_state, @id_two_b)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = paired_state

    assert winner == false
    assert animating == false
    assert Enum.count(cards) == 4

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == false
    assert flip_four == false

    assert paired_one == false
    assert paired_two == false
    assert paired_three == true
    assert paired_four == true
  end

  test "flipping the 2nd card that is NOT a match will mark the cards as flipped but not paired" do
    state = Game.Engine.new(@playing_cards, FakeRandom)
    new_state = Game.Engine.flip(state, @id_two_a)
    incorrect_state = Game.Engine.flip(new_state, @id_one_a)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = incorrect_state

    assert winner == false
    assert animating == true
    assert Enum.count(cards) == 4

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == true
    assert flip_two == false
    assert flip_three == true
    assert flip_four == false

    assert paired_one == false
    assert paired_two == false
    assert paired_three == false
    assert paired_four == false
  end

  test "flipping when animating is marked as true flip does nothing" do
    state = %Game.Engine{
      cards: [
        %Card{:id => "24CEDF1", :flipped => false, :paired => false},
        %Card{:id => "3079821", :flipped => true, :paired => false},
        %Card{:id => "24CEDF2", :flipped => true, :paired => false},
        %Card{:id => "3079822", :flipped => false, :paired => false}
      ],
      winner: nil,
      animating: true
    }

    new_state = Game.Engine.flip(state, @id_two_a)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = new_state

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == true
    assert flip_three == true
    assert flip_four == false

    assert paired_one == false
    assert paired_two == false
    assert paired_three == false
    assert paired_four == false

    assert winner == nil
    assert animating == true
  end

  test "flipping when winner is marked as true flip does nothing" do
    state = %Game.Engine{
      cards: [
        %Card{:id => "24CEDF1", :flipped => false, :paired => true},
        %Card{:id => "3079821", :flipped => false, :paired => true},
        %Card{:id => "24CEDF2", :flipped => false, :paired => true},
        %Card{:id => "3079822", :flipped => false, :paired => true}
      ],
      winner: true,
      animating: false
    }

    new_state = Game.Engine.flip(state, @id_two_a)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = new_state

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == false
    assert flip_four == false

    assert paired_one == true
    assert paired_two == true
    assert paired_three == true
    assert paired_four == true

    assert winner == true
    assert animating == false
  end

  test "unflip will reset animating to false and revert any flipped cards" do
    state = Game.Engine.new(@playing_cards, FakeRandom)
    new_state = Game.Engine.flip(state, @id_two_a)
    incorrect_state = Game.Engine.flip(new_state, @id_one_a)
    unflipped_state = Game.Engine.unflip(incorrect_state)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = unflipped_state

    assert winner == false
    assert animating == false
    assert Enum.count(cards) == 4

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == false
    assert flip_four == false

    assert paired_one == false
    assert paired_two == false
    assert paired_three == false
    assert paired_four == false
  end

  test "flipping the last match will mark the winner as truthy" do
    state = Game.Engine.new(@playing_cards, FakeRandom)
    flip_one_state = Game.Engine.flip(state, @id_two_a)
    paired_one_state = Game.Engine.flip(flip_one_state, @id_two_b)
    flip_two_state = Game.Engine.flip(paired_one_state, @id_one_a)
    paired_two_state = Game.Engine.flip(flip_two_state, @id_one_b)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = paired_two_state

    assert winner == true
    assert animating == false
    assert Enum.count(cards) == 4

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == false
    assert flip_four == false

    assert paired_one == true
    assert paired_two == true
    assert paired_three == true
    assert paired_four == true
  end

  test "prepare restart will unpair each card" do
    state = %Game.Engine{
      cards: [
        %Card{:id => "24CEDF1", :flipped => false, :paired => true},
        %Card{:id => "3079821", :flipped => false, :paired => true},
        %Card{:id => "24CEDF2", :flipped => false, :paired => true},
        %Card{:id => "3079822", :flipped => false, :paired => true}
      ],
      winner: true,
      animating: false
    }

    prepare_restart_state = Game.Engine.prepare_restart(state)

    %Game.Engine{cards: cards} = prepare_restart_state

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == false
    assert flip_three == false
    assert flip_four == false

    assert paired_one == false
    assert paired_two == false
    assert paired_three == false
    assert paired_four == false
  end

  test "prepare restart does nothing if winner is nil" do
    state = %Game.Engine{
      cards: [
        %Card{:id => "24CEDF1", :flipped => false, :paired => true},
        %Card{:id => "3079821", :flipped => true, :paired => false},
        %Card{:id => "24CEDF2", :flipped => false, :paired => true},
        %Card{:id => "3079822", :flipped => false, :paired => false}
      ],
      winner: nil,
      animating: false
    }

    new_state = Game.Engine.prepare_restart(state)

    %Game.Engine{cards: cards, winner: winner, animating: animating} = new_state

    [
      %Card{flipped: flip_one, paired: paired_one},
      %Card{flipped: flip_two, paired: paired_two},
      %Card{flipped: flip_three, paired: paired_three},
      %Card{flipped: flip_four, paired: paired_four}
    ] = cards

    assert flip_one == false
    assert flip_two == true
    assert flip_three == false
    assert flip_four == false

    assert paired_one == true
    assert paired_two == false
    assert paired_three == true
    assert paired_four == false

    assert winner == nil
    assert animating == false
  end

  test "restart will flip winner to false" do
    state = %Game.Engine{
      cards: [
        %Card{:id => "24CEDF1", :flipped => false, :paired => false},
        %Card{:id => "3079821", :flipped => false, :paired => false},
        %Card{:id => "24CEDF2", :flipped => false, :paired => false},
        %Card{:id => "3079822", :flipped => false, :paired => false}
      ],
      winner: true,
      animating: false,
      playing_cards: @playing_cards,
      random: FakeRandom
    }

    restart_state = Game.Engine.restart(state)

    %Game.Engine{winner: winner} = restart_state

    assert winner == false
  end
end
