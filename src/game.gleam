import gleam/map
import gleam/bool
import gleam/list
import gleam/string

pub type Card {
  Card(id: String, name: String, image: String, flipped: Bool, paired: Bool)
}

pub type Engine {
  Engine(
    cards: List(Card),
    winner: Bool,
    animating: Bool,
    score: Int,
    playing_cards: List(String),
    random: Bool,
  )
}

pub fn pair_cards(cards: List(Card), engine: Engine) -> Engine {
  let paired_cards =
    list.map(
      cards,
      fn(card: Card) {
        case card.flipped {
          True -> Card(..card, paired: True, flipped: False)
          _ -> card
        }
      },
    )

  Engine(..engine, cards: paired_cards)
}

pub fn declare_winner(engine: Engine) -> Engine {
  let total = list.length(engine.cards)
  let paired =
    list.filter(engine.cards, fn(card: Card) { card.paired == True })
    |> list.length()

  case total == paired {
    True -> Engine(..engine, winner: True)
    _ -> Engine(..engine, winner: False)
  }
}

pub fn attempt_match(cards: List(Card), engine: Engine) -> Engine {
  let flipped_cards =
    list.filter(cards, fn(card: Card) { card.flipped == True })
    |> list.map(fn(card: Card) { card.name })

  case list.length(flipped_cards) == 2 {
    True ->
      case flipped_cards {
        [one, two] if one == two -> pair_cards(cards, engine)
        _ -> Engine(..engine, cards: cards, animating: True)
      }

    _ -> Engine(..engine, cards: cards)
  }
}

pub fn flip(engine: Engine, flip_id: String) -> Engine {
  case engine.animating, engine.winner {
    _, True -> engine

    True, _ -> engine

    _, _ ->
      list.map(
        engine.cards,
        fn(card: Card) {
          case card.id == flip_id {
            True -> Card(..card, flipped: True)
            _ -> card
          }
        },
      )
      |> attempt_match(engine)
      |> declare_winner()
  }
}

pub fn unpair_cards(engine: Engine) -> Engine {
  let unpaired =
    list.map(engine.cards, fn(card: Card) { Card(..card, paired: False) })
  Engine(..engine, cards: unpaired)
}

pub fn prepare_restart(engine: Engine) -> Engine {
  case engine.winner {
    True -> unpair_cards(engine)
    _ -> engine
  }
}

pub fn unflip(engine: Engine) -> Engine {
  let cards =
    list.map(engine.cards, fn(card: Card) { Card(..card, flipped: False) })

  Engine(..engine, cards: cards, animating: False)
}

pub fn generate_cards(playing_cards: List(String)) -> List(Card) {
  list.map(
    playing_cards,
    fn(name: String) {
      let one =
        Card(
          id: string.join([name, "1"], with: ""),
          name: name,
          image: string.join(["/images/cards/", name, ".png"], with: ""),
          flipped: False,
          paired: False,
        )
      let two =
        Card(
          id: string.join([name, "2"], with: ""),
          name: name,
          image: string.join(["/images/cards/", name, ".png"], with: ""),
          flipped: False,
          paired: False,
        )
      [one, two]
    },
  )
  |> list.flatten()
}

pub fn init(playing_cards: List(String), random: Bool) -> Engine {
  let total = list.length(playing_cards)

  let cards = case random {
    True ->
      generate_cards(playing_cards)
      |> list.take(total * 2)

    False ->
      generate_cards(playing_cards)
      |> list.take(total * 2)
  }

  Engine(
    cards: cards,
    winner: False,
    animating: False,
    score: 0,
    playing_cards: playing_cards,
    random: random,
  )
}
