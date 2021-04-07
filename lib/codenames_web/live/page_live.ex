defmodule CodenamesWeb.PageLive do
  use CodenamesWeb, :live_view

  alias Codenames.GameState

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(:game_state, GameState.value())
    {:ok, socket}
  end
end
