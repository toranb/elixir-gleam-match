defmodule GameWeb.PageController do
  use GameWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    game_name = Game.Generator.haiku()

    case Game.SessionSupervisor.start_game(game_name) do
      {:ok, _pid} ->
        redirect(conn, to: Routes.page_path(conn, :play, game_name))

      {:error, {:already_started, _pid}} ->
        redirect(conn, to: Routes.page_path(conn, :play, game_name))

      {:error, _error} ->
        render(conn, "index.html")
    end
  end

  def play(conn, %{"id" => game_name}) do
    case Game.Session.session_pid(game_name) do
      pid when is_pid(pid) ->
        render_live_view(conn, game_name)

      nil ->
        redirect_user(conn)
    end
  end

  def redirect_user(conn) do
    conn
    |> put_flash(:error, "game not found")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  def render_live_view(conn, game_name) do
    Phoenix.LiveView.Controller.live_render(conn, GameWeb.PageLive,
      session: %{
        "game_name" => game_name,
        "error" => nil
      }
    )
  end
end
