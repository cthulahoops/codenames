defmodule Codenames.GameState do
  use Agent

  defstruct [:cards, :key, :current_team]

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
      current_team: start_team }
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def cards do
    Agent.get(__MODULE__, fn state -> state.cards end)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end
end
