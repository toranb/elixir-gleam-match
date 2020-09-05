defmodule GameWeb.PageLive do
  use GameWeb, :live_view

  @impl true
  def mount(_params, %{"game_name" => game_name}, socket) do
    state = Game.Session.game_state(game_name)

    {:ok, set_state(socket, state, %{game_name: game_name})}
  end

  @impl true
  def handle_event("flip", %{"flip-id" => flip_id}, socket) do
    %{:game_name => game_name} = socket.assigns

    case Game.Session.session_pid(game_name) do
      pid when is_pid(pid) ->
        state = Game.Session.flip(game_name, flip_id)
        %Game.Engine{animating: animating} = state

        if animating == true do
          send(self(), {:unflip, game_name})
        end

        {:noreply, set_state(socket, state, socket.assigns)}

      nil ->
        {:noreply, set_error(socket)}
    end
  end

  @impl true
  def handle_event("prepare_restart", _value, socket) do
    %{:game_name => game_name} = socket.assigns

    case Game.Session.session_pid(game_name) do
      pid when is_pid(pid) ->
        state = Game.Session.prepare_restart(game_name)
        send(self(), {:restart, game_name})
        {:noreply, set_state(socket, state, socket.assigns)}

      nil ->
        {:noreply, set_error(socket)}
    end
  end

  @impl true
  def handle_info({:unflip, game_name}, socket) do
    case Game.Session.session_pid(game_name) do
      pid when is_pid(pid) ->
        state = Game.Session.unflip(game_name)

        {:noreply, set_state(socket, state, socket.assigns)}

      nil ->
        {:noreply, set_error(socket)}
    end
  end

  @impl true
  def handle_info({:restart, game_name}, socket) do
    case Game.Session.session_pid(game_name) do
      pid when is_pid(pid) ->
        state = Game.Session.restart(game_name)

        {:noreply, set_state(socket, state, socket.assigns)}

      nil ->
        {:noreply, set_error(socket)}
    end
  end

  def rows(%{cards: cards}) do
    Enum.map(cards, &Map.from_struct(&1))
  end

  def set_state(socket, state, %{game_name: game_name}) do
    %Game.Engine{cards: cards, winner: winner, score: score} = state

    assign(socket,
      game_name: game_name,
      cards: cards,
      winner: winner,
      score: score
    )
  end

  def set_error(socket) do
    assign(socket,
      error: "an error occurred"
    )
  end

  def clazz(%{flipped: flipped, paired: paired}) do
    case paired == true do
      true ->
        "found"

      false ->
        case flipped == true do
          true -> "flipped"
          false -> ""
        end
    end
  end
end
