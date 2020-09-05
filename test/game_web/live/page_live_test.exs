defmodule GameWeb.PageLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Game.FakeRandom

  @endpoint GameWeb.Endpoint
  @one "/images/cards/one.png"
  @two "/images/cards/two.png"
  @id_one_a "24CEDF1"
  @id_one_b "24CEDF2"
  @id_two_a "3079821"
  @id_two_b "3079822"

  setup config do
    patch_process()

    playing_cards = ["one", "two"]
    game_name = Game.Generator.haiku()
    {:ok, pid} = Game.SessionSupervisor.start_game(game_name, playing_cards, FakeRandom)

    on_exit(fn ->
      Process.exit(pid, :kill)
      purge(Game.Process)
    end)

    conn = Plug.Test.init_test_session(Phoenix.ConnTest.build_conn(), config[:session] || %{})

    %{conn: conn, game_name: game_name}
  end

  test "each card will be rendered with correct click handler, value and background image", %{
    conn: conn,
    game_name: game_name
  } do
    {:ok, _view, html} = live(conn, "/play/#{game_name}")

    {:ok, html} = html |> Floki.parse_document()
    cards = Floki.find(html, ".card")
    assert Enum.count(cards) == 4

    assert ["card", "card", "card", "card"] == card_classes(cards)
    assert ["flip", "flip", "flip", "flip"] == click_handlers(cards)
    assert [@id_one_a, @id_one_b, @id_two_a, @id_two_b] == click_values(cards)

    assert [
             "background-image: url(#{@one})",
             "background-image: url(#{@one})",
             "background-image: url(#{@two})",
             "background-image: url(#{@two})"
           ] == child_styles(cards)
  end

  test "flipping 2 incorrect matches will unflip after a brief pause", %{
    conn: conn,
    game_name: game_name
  } do
    {:ok, view, html} = live(conn, "/play/#{game_name}")

    {:ok, html} = html |> Floki.parse_document()
    cards = Floki.find(html, ".card")
    assert ["card", "card", "card", "card"] == card_classes(cards)

    flip_one_html = render_click(view, :flip, %{"flip-id" => @id_two_a})
    {:ok, flip_one_html} = flip_one_html |> Floki.parse_document()
    flip_one_cards = Floki.find(flip_one_html, ".card")
    assert ["card", "card", "card flipped", "card"] == card_classes(flip_one_cards)

    flip_two_html = render_click(view, :flip, %{"flip-id" => @id_one_b})
    {:ok, flip_two_html} = flip_two_html |> Floki.parse_document()
    flip_two_cards = Floki.find(flip_two_html, ".card")
    assert ["card", "card flipped", "card flipped", "card"] == card_classes(flip_two_cards)

    Process.sleep(20)

    {:ok, final_html} = render(view) |> Floki.parse_document()
    final_cards = Floki.find(final_html, ".card")
    assert ["card", "card", "card", "card"] == card_classes(final_cards)
  end

  test "flipping 2 correct matches will mark a pair", %{conn: conn, game_name: game_name} do
    {:ok, view, html} = live(conn, "/play/#{game_name}")

    {:ok, html} = html |> Floki.parse_document()
    cards = Floki.find(html, ".card")
    assert ["card", "card", "card", "card"] == card_classes(cards)

    flip_one_html = render_click(view, :flip, %{"flip-id" => @id_two_a})
    {:ok, flip_one_html} = flip_one_html |> Floki.parse_document()
    flip_one_cards = Floki.find(flip_one_html, ".card")
    assert ["card", "card", "card flipped", "card"] == card_classes(flip_one_cards)

    flip_two_html = render_click(view, :flip, %{"flip-id" => @id_two_b})
    {:ok, flip_two_html} = flip_two_html |> Floki.parse_document()
    flip_two_cards = Floki.find(flip_two_html, ".card")
    assert ["card", "card", "card found", "card found"] == card_classes(flip_two_cards)
  end

  test "flipping all correct matches will show modal", %{conn: conn, game_name: game_name} do
    {:ok, view, html} = live(conn, "/play/#{game_name}")

    {:ok, html} = html |> Floki.parse_document()
    assert Enum.count(modal(html)) == 0

    render_click(view, :flip, %{"flip-id" => @id_two_a})
    render_click(view, :flip, %{"flip-id" => @id_two_b})

    {:ok, one_pair_html} = render(view) |> Floki.parse_document()
    assert Enum.count(modal(one_pair_html)) == 0

    render_click(view, :flip, %{"flip-id" => @id_one_a})
    render_click(view, :flip, %{"flip-id" => @id_one_b})

    {:ok, two_pair_html} = render(view) |> Floki.parse_document()

    assert Enum.count(modal(two_pair_html)) == 1
    assert winner(two_pair_html) == "You Won!"
  end

  test "clicking play again will reset the game and hide the modal", %{
    conn: conn,
    game_name: game_name
  } do
    {:ok, view, _html} = live(conn, "/play/#{game_name}")

    render_click(view, :flip, %{"flip-id" => @id_two_a})
    render_click(view, :flip, %{"flip-id" => @id_two_b})

    render_click(view, :flip, %{"flip-id" => @id_one_a})
    render_click(view, :flip, %{"flip-id" => @id_one_b})

    winner_html = render(view)
    {:ok, winner_html} = winner_html |> Floki.parse_document()
    winner_cards = Floki.find(winner_html, ".card")
    assert ["card found", "card found", "card found", "card found"] == card_classes(winner_cards)
    assert Enum.count(modal(winner_html)) == 1

    restart_html = render_click(view, :prepare_restart)
    Process.sleep(2)

    {:ok, restart_html} = restart_html |> Floki.parse_document()
    restart_cards = Floki.find(restart_html, ".card")
    assert ["card", "card", "card", "card"] == card_classes(restart_cards)

    {:ok, restarted_html} = render(view) |> Floki.parse_document()
    assert Enum.count(modal(restarted_html)) == 0
  end

  defp modal(html) do
    Floki.find(html, ".splash, .overlay")
  end

  defp winner(html) do
    Floki.find(html, ".content h1") |> Floki.text()
  end

  defp card_classes(cards) do
    cards
    |> Floki.attribute("class")
    |> Enum.map(&String.trim(&1))
  end

  defp click_handlers(cards) do
    cards
    |> Floki.attribute("phx-click")
  end

  defp click_values(cards) do
    cards
    |> Floki.attribute("phx-value-flip-id")
  end

  defp child_styles(cards) do
    cards
    |> Enum.map(fn {_tag, _attr, child} ->
      [_, front] = child
      [attribute] = Floki.attribute(front, "style")
      attribute
    end)
  end

  defp patch_process do
    Code.eval_string("""
      defmodule Game.Process do
        def sleep(t) do
          Process.sleep(t)
        end
      end
    """)
  end

  defp purge(module) do
    :code.purge(module)
    :code.delete(module)
  end
end
