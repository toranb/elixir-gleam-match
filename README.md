## Installation

To install on macOS

```
brew install gleam
```

## Objectives

The entire project centers around a single Gleam source file. The game [engine](https://github.com/toranb/elixir-gleam-match/blob/master/src/game.gleam) is driven from the elixir [wrapper](https://github.com/toranb/elixir-gleam-match/blob/master/lib/game/engine.ex)

```elixir
defmodule Game.Engine do
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
end
```

### flip

![flipp](https://user-images.githubusercontent.com/147411/67634906-5d400800-f88f-11e9-8d3e-125fc09268a1.gif)

This function is executed when the player clicks a playing card. Simply enumerate the cards and mark the one with the id as `flipped` using a boolean. If 2 cards have been flipped at this point attempt to match them by the id. When a match is found mark each card as `paired` and set the `flipped` for both back to false. Finally, if all the cards are paired declare the game over by marking the `winner` using a boolean value.

One edge case here is that if 2 cards are flipped but they do *not* match, you need to set the `animating` boolean to true. This will later instruct the engine to fire `unflip`.

### unflip

![unfliip](https://user-images.githubusercontent.com/147411/67634902-4ac5ce80-f88f-11e9-8bbe-451093d55e4d.gif)

This function is executed after a 2nd card has flipped but failed to match. Simply enumerate the cards and mark the `flipped` attribute to false for any non paired card. You will also need to revert `animating` to false so the flip function works properly.

### prepare_restart

![prepareRestart](https://user-images.githubusercontent.com/147411/67634990-ed7e4d00-f88f-11e9-8af0-03c456c2e466.gif)

This function is executed after the player decides to play again. Simply enumerate the cards and mark all `paired` and `flipped` attributes to false.

## Debugging Tips

To print something in the Gleam source code import the io module and use `io.debug`

```elixir
import gleam/io

io.debug("Hello World!")
```

## Learning Gleam

Because the language is so young today the best place to dive in is the [getting started](https://gleam.run/) guide

## License

Copyright © 2020 Toran Billups https://toranbillups.com

Licensed under the MIT License
