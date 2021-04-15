defmodule Codenames.GameState do
  use Agent

  defstruct [:cards, :key, :current_team, :clue, :team_red, :team_blue]

  defmodule Clue do
    defstruct [:word, :count]
  end

  defmodule Team do
    defstruct [:spymaster, agents: []]

    def add_player(team, key, name) do
      if is_nil team.spymaster do
        {:spymaster, %Team{ team | spymaster: {key, name}}}
      else
        {:agent, %Team{ team | agents: team.agents ++ [{key, name}]}}
      end
    end

    def count(team) do
      if is_nil team.spymaster do
        Enum.count(team.agents)
      else
        1 + Enum.count(team.agents)
      end
    end

    def role(%Team{spymaster: {key, _}}, key), do: :spymaster
    def role(%Team{agents: agents}, key) do
      if Enum.any?(agents, fn {k, _} -> k == key end) do
        :agent
      end
    end
  end

  def draw_cards() do
    wordlist_path = Path.join(:code.priv_dir(:codenames), "wordlist.txt")
    File.read!(wordlist_path) |> String.split() |> Enum.shuffle |> Enum.take(25)
  end

  def draw_key(start_team) do
    items = List.duplicate(:red, 8)
    ++ List.duplicate(:blue, 8)
    ++ List.duplicate(:bystander, 7)
    ++ [start_team, :assassin]
    Enum.shuffle items
  end

  def start_link([]) do
    start_team = Enum.random([:red, :blue])

    initial_state = %Codenames.GameState{
      cards: draw_cards(),
      key: draw_key(start_team),
      current_team: start_team,
      team_red: %Team{},
      team_blue: %Team{}}
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def cards do
    Agent.get(__MODULE__, fn state -> state.cards end)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end


  def update(f) do
    Agent.update(__MODULE__, fn state ->
      state = f.(state)
      Phoenix.PubSub.broadcast(Codenames.PubSub, "game_state", {:game_state_updated, state})
      state
    end)
  end

  def get_and_update(f) do
    Agent.get_and_update(__MODULE__, fn state ->
      {get, update} = f.(state)
      Phoenix.PubSub.broadcast(Codenames.PubSub, "game_state", {:game_state_updated, update})
      {get, update}
    end)
  end

  def set_clue(word, count) do
    update(fn state -> %Codenames.GameState{state | clue: %Clue{word: word, count: String.to_integer(count)}} end)
  end

  def role(state, key) do
    cond do
      role = Team.role(state.team_red, key) -> {:red, role}
      role = Team.role(state.team_blue, key) -> {:blue, role}
      true -> nil
    end
  end

  def add_player(key, name) do
    get_and_update(fn state ->
      cond do
        role = role(state, key) -> {role, state}
        Team.count(state.team_red) < Team.count(state.team_blue) ->
          {role, team} = Team.add_player(state.team_red, key, name)
          {{:red, role}, %{state | team_red: team}}
        true ->
          {role, team} = Team.add_player(state.team_blue, key, name)
          {{:blue, role}, %{state | team_blue: team}}
        end
     end
     )
  end

  def subscribe do
    pid = Process.whereis(__MODULE__)
    Process.monitor(pid)

    Phoenix.PubSub.subscribe(Codenames.PubSub, "game_state")
    value()
  end
end
