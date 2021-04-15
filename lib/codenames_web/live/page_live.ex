defmodule CodenamesWeb.PageLive do
  use CodenamesWeb, :live_view

  alias Codenames.GameState

  @spy_names [
    "Julius",
    "Ethel",
    "Harriet",
    "James",
    "Phillip",
    "Nero",
    "Jason",
    "Number 6",
    "Austin",
    "Mata",
    "Krystyna"
  ]

  @impl true
  def mount(_params, session, socket) do
    socket =
      if connected?(socket) do
        socket
        |> join_game(session["key"])
      else
        socket
      end

    socket =
      socket
      |> assign_defaults(session)

    {:ok, socket}
  end

  def assign_defaults(socket, session) do
    socket
    |> assign_new(:game_state, &GameState.value/0)
    |> assign_new(:role, fn -> nil end)
    |> assign_new(:team, fn -> nil end)
    |> assign_new(:name, fn -> nil end)
    |> assign_new(:key, fn -> session["key"] end)
  end

  def join_game(socket, session_key) do
    name = Enum.random(@spy_names)
    {team, role} = register_player(session_key, name)
    game_state = GameState.subscribe()

    socket
    |> assign(:name, name)
    |> assign(:game_state, game_state)
    |> assign(:role, role)
    |> assign(:team, team)
  end

  def register_player(session_key, name) when not is_nil(session_key) do
    GameState.add_player(session_key, name)
  end

  @impl true
  def handle_event("set_clue", %{"clue" => clue, "count" => count}, socket) do
    GameState.set_clue(clue, count)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_state_updated, game_state = %GameState{}}, socket) do
    socket = socket |> assign(:game_state, game_state)
    {:noreply, socket}
  end
end
