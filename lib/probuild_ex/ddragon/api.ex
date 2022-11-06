defmodule ProbuildEx.Ddragon.Api do
  use Tesla, only: [:get]

  @local "en_US"

  plug Tesla.Middleware.BaseUrl, "https://ddragon.leagueoflegends.com"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  def fetch_versions(), do: get("/api/versions.json")

  def fetch(:champions, patch_version) do
    fetch_json(patch_version, "champion")
  end

  def fetch(:summoners, patch_version) do
    fetch_json(patch_version, "summoner")
  end

  def fetch(:items, patch_version) do
    fetch_json(patch_version, "item")
  end

  defp fetch_json(patch, type) do
    get("/cdn/#{patch}/data/#{@local}/#{type}.json")
  end
end
