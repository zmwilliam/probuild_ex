defmodule ProbuildEx.Canon.Games do
  alias ProbuildEx.{RiotApi, Games}
  alias ProbuildEx.Games.Summoner

  require Logger

  def run(platform_id \\ "euw1") do
    region_client = RiotApi.new(platform_id, :convert_platform_to_region_id)
    platform_client = RiotApi.new(platform_id)

    platform_id
    |> Games.list_pro_summoners()
    |> Stream.map(fn %Summoner{} = summoner ->
      RiotApi.list_matches(region_client, summoner.puuid)
    end)
    |> Stream.flat_map(&Games.reject_existing_games/1)
    |> Stream.map(fn game_riot_id ->
      with {:ok, match_data} <- RiotApi.fetch_match(region_client, game_riot_id),
           {:ok, summoner_list} <- fetch_summoners(platform_id, platform_client, match_data) do
        {match_data, summoner_list}
      end
    end)
    |> Stream.reject(&Kernel.match?({:error, _}, &1))
    |> Stream.map(fn {match_data, summoner_list} ->
      platform_id
      |> Games.create_game_complete(match_data, summoner_list)
      |> log_failed_transaction()
    end)
    |> Stream.run()
  end

  defp fetch_summoners(platform_id, client, match_data) do
    match_data
    |> get_in(["metadata", "participants"])
    |> Enum.reduce_while([], fn puuid, acc ->
      with {:error, :not_found} <- Games.fetch_summoner(puuid: puuid, platform_id: platform_id),
           {:ok, summoner_data} <- RiotApi.fetch_summoner_by_puuid(client, puuid) do
        {:cont, [summoner_data | acc]}
      else
        {:ok, summoner} -> {:cont, [summoner | acc]}
        {:error, :not_found} -> {:halt, []}
      end
    end)
    |> case do
      [] -> {:error, :summoner_puuid_not_found}
      summoner_list -> {:ok, summoner_list}
    end
  end

  defp log_failed_transaction(result) do
    case result do
      {:ok, _} ->
        :ok

      {:error, :game, %{errors: _}, _} ->
        :ok

      {:error, {:participant, _}, %{errors: [{:team_position, _}]}, _} ->
        :ok

      {:error, err} ->
        Logger.error(err)

      {:error, multi_name, changeset, multi} ->
        Logger.error("""
          multi_name: 
          #{inspect(multi_name)}
          changeset: 
          #{inspect(changeset)}
          multi:
          #{inspect(multi)}
        """)
    end
  end
end
