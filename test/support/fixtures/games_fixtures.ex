defmodule ProbuildEx.GamesFixtures do
  @moduledoc false

  def unique_team_name, do: "team name #{System.unique_integer([:positive])}"

  def team_fixture(name \\ unique_team_name()) do
    {:ok, team} = ProbuildEx.Games.fetch_or_create_team(name)

    team
  end

  def unique_pro_name, do: "pro name #{System.unique_integer([:positive])}"

  def pro_fixture(name \\ unique_pro_name(), team \\ team_fixture()) do
    {:ok, pro} = ProbuildEx.Games.fetch_or_create_pro(name, team.id)
    pro
  end

  def unique_summoner_attrs(attrs \\ %{}) do
    name = "summoner name %{System.unique_integer([:positive])}"
    puuid = Ecto.UUID.generate()

    Enum.into(attrs, %{
      "name" => name,
      "platform_id" => "euw1",
      "puuid" => puuid
    })
  end

  def summoner_fixture(attrs \\ %{}, pro \\ pro_fixture()) do
    attrs =
      attrs
      |> Map.put("pro_id", pro.id)
      |> unique_summoner_attrs()

    {:ok, summoner} = ProbuildEx.Games.create_summoner(attrs)
    summoner
  end
end
