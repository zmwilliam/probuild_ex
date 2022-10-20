defmodule ProbuildEx.RiotApi do
  @moduledoc false

  require Logger

  @ranked_solo_game 420

  @regions_routing_map %{
    "americas" => ["na1", "br1", "la1", "la2"],
    "asia" => ["kr", "jp1"],
    "europe" => ["eun1", "euw1", "tr1", "ru"],
    "sea" => ["oc1"]
  }

  @regions Map.keys(@regions_routing_map)

  @platform_ids_routing_map %{
    "br1" => "americas",
    "jp1" => "asia",
    "kr" => "asia",
    "la1" => "americas",
    "la2" => "americas",
    "na1" => "americas",
    "oc1" => "sea",
    "ru" => "europe",
    "tr1" => "europe",
    "eun1" => "europe",
    "euw1" => "europe"
  }

  @platform_ids Map.keys(@platform_ids_routing_map)

  def token do
    Application.get_env(:probuild_ex, __MODULE__)[:token]
  end

  def new(region, option \\ nil) do
    middlewares = [
      {Tesla.Middleware.Retry,
       [
         delay: 10_000,
         max_retries: 20,
         max_delay: 60_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [429, 503] -> true
           {:ok, _} -> false
           {:error, _} -> true
         end
       ]},
      {Tesla.Middleware.Headers, [{"X-Riot-Token", token()}]},
      {Tesla.Middleware.BaseUrl, url(region, option)},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middlewares)
  end

  defp url(region_or_platform_id, option)

  defp url(region, nil) when region in @regions do
    "https://#{region}.api.riotgames.com"
  end

  defp url(platform_id, nil) when platform_id in @platform_ids do
    "https://#{platform_id}.api.riotgames.com"
  end

  defp url(platform_id, :convert_platform_to_region_id) when platform_id in @platform_ids do
    region = Map.get(@platform_ids_routing_map, platform_id)
    url(region, nil)
  end

  def list_matches(client, puuid, start \\ 0) do
    path = "/lol/match/v5/matches/by-puuid/#{puuid}/ids?"
    query = URI.encode_query(start: start, count: 100, queue: @ranked_solo_game)

    %{body: match_ids, status: 200} = Tesla.get!(client, path <> query)
    match_ids
  end

  def fetch_match(client, match_id) do
    path = "/lol/match/v5/matches/#{match_id}"
    fetch(client, path)
  end

  def fetch_summoner_by_name(client, name) do
    path = "/lol/summoner/v4/summoners/by-name/#{name}"
    fetch(client, path)
  end

  def fetch_summoner_by_puuid(client, uuid) do
    path = "/lol/summoner/v4/summoners/by-puuid/#{uuid}"
    fetch(client, path)
  end

  defp fetch(client, path) do
    encoded_path = URI.encode(path)

    case Tesla.get!(client, encoded_path) do
      %{status: 200, body: data} ->
        {:ok, data}

      %{status: 404} ->
        {:error, :not_found}

      other ->
        Logger.error(other)
        {:error, :unknow_error}
    end
  end
end
