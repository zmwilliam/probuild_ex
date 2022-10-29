defmodule ProbuildEx.Games do
  @moduledoc """
  The context module to manage the creation / updtate of schemas
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ProbuildEx.Repo
  alias ProbuildEx.Games.{Team, Pro, Summoner, Game, Participant}

  @positions Participant.get_positions() |> Enum.map(&to_string/1)

  @doc """
  Given an platform_id return all pros summoners
  """
  def list_pro_summoners(platform_id) do
    query =
      from summoner in Summoner,
        where: summoner.platform_id == ^platform_id and not is_nil(summoner.pro_id),
        order_by: [desc: summoner.updated_at]

    Repo.all(query)
  end

  @doc """
  Given a list of riot ids games return a list of the ones that does not exist in database
  """
  def reject_existing_games(riot_ids) do
    query =
      from game in Game,
        where: game.riot_id in ^riot_ids,
        select: game.riot_id

    existing_riot_ids = Repo.all(query)
    Enum.reject(riot_ids, fn id -> id in existing_riot_ids end)
  end

  def create_game_complete(platform_id, match_data, summoners_list) do
    multi = Multi.insert(Multi.new(), :game, change_game(match_data))

    multi =
      Enum.reduce(summoners_list, multi, fn summoner, multi ->
        reduce_put_or_create_summoner(platform_id, summoner, multi)
      end)

    participants = get_in(match_data, ["info", "participants"])

    multi = Enum.reduce(participants, multi, &reduce_create_participant/2)
    multi = Enum.reduce(participants, multi, &reduce_set_opponent_participant/2)

    Repo.transaction(multi)
  end

  defp reduce_set_opponent_participant(data, multi) do
    Multi.update(
      multi,
      {:update_participant, data["puuid"]},
      fn changes ->
        with {:ok, participant_key} <- fetch_participant_key(data),
             {:ok, opponent_participant_key} <- fetch_opponent_participant_key(data),
             {:ok, participant} <- Map.fetch(changes, {:participant, participant_key}),
             {:ok, opponent_participant} <-
               Map.fetch(changes, {:participant, opponent_participant_key}) do
          change_participant_opponent(participant, opponent_participant.id)
        else
          _ ->
            Ecto.Changeset.add_error(%Ecto.Changeset{}, :participant, "not_found")
        end
      end
    )
  end

  defp reduce_create_participant(participant_data, multi) do
    participant_data
    |> fetch_participant_key()
    |> reduce_create_participant(participant_data, multi)
  end

  defp reduce_create_participant({:ok, participant_key}, participant_data, multi) do
    Multi.insert(
      multi,
      {:participant, participant_key},
      fn changes ->
        case Map.fetch(changes, {:summoner, participant_data["puuid"]}) do
          {:ok, summoner} ->
            change_participant(changes.game, participant_data, summoner)

          :error ->
            Ecto.Changeset.add_error(%Ecto.Changeset{}, :summoner, "not_found")
        end
      end
    )
  end

  defp reduce_create_participant(:error, _data, multi), do: multi

  def change_participant(game, data, summoner) do
    attrs = %{
      kills: Map.get(data, "kills"),
      deaths: Map.get(data, "deaths"),
      assists: Map.get(data, "assists"),
      champion_id: Map.get(data, "championId"),
      gold_earned: Map.get(data, "goldEarned"),
      summoners: Map.take(data, ["summoner1Id", "summoner2Id"]) |> Map.values(),
      items: Map.take(data, for(n <- 0..6, do: "item#{n}")) |> Map.values(),
      team_position: Map.get(data, "teamPosition"),
      game_id: game.id,
      summoner_id: summoner.id,
      team_id: Map.get(data, "teamId"),
      win: Map.get(data, "win")
    }

    Participant.changeset(attrs)
  end

  def change_participant_opponent(participant, opponent_participant_id) do
    Participant.changeset(participant, %{opponent_participant_id: opponent_participant_id})
  end

  defp fetch_participant_key(data) do
    with {:ok, team_id} <- Map.fetch(data, "teamId"),
         true <- team_id in [100, 200],
         {:ok, team_position} <- Map.fetch(data, "teamPosition"),
         true <- is_binary(team_position) and team_position in @positions do
      {:ok, {team_id, team_position}}
    else
      _ -> :error
    end
  end

  defp fetch_opponent_participant_key(data) do
    with {:ok, {team_id, team_position}} <- fetch_participant_key(data),
         enemy_team_id <- get_enemy_team_id(team_id) do
      {:ok, {enemy_team_id, team_position}}
    else
      _ -> :error
    end
  end

  defp get_enemy_team_id(100), do: 200
  defp get_enemy_team_id(200), do: 100

  defp reduce_put_or_create_summoner(_platform_id, %Summoner{} = summoner, multi) do
    Multi.put(multi, {:summoner, summoner.puuid}, summoner)
  end

  defp reduce_put_or_create_summoner(platform_id, summoner_data, multi) do
    case Map.fetch(summoner_data, "puuid") do
      {:ok, puuid} ->
        summoner_data
        |> Map.put("platform_id", platform_id)
        |> Summoner.changeset()
        |> then(&Multi.insert(multi, {:summoner, puuid}, &1))

      {:error} ->
        multi
    end
  end

  defp change_game(match_data) do
    attrs = %{
      creation_int: get_in(match_data, ["info", "gameCreation"]),
      duration: get_in(match_data, ["info", "gameDuration"]),
      platform_id: get_in(match_data, ["info", "platformId"]) |> String.downcase(),
      riot_id: get_in(match_data, ["metadata", "matchId"]),
      version: get_in(match_data, ["info", "gameVersion"]),
      winner: get_winner_team(match_data)
    }

    Game.changeset(attrs)
  end

  defp get_winner_team(match_data) do
    match_data
    |> get_in(~w(info teams)s)
    |> Enum.filter(fn team -> team["win"] end)
    |> List.first()
    |> Kernel.||(%{})
    |> Map.get("teamId")
  end

  def create_pro_complete(ugg_pro, summoner_data) do
    Repo.transaction(fn ->
      with {:ok, team} <- fetch_or_create_team(ugg_pro["current_team"]),
           {:ok, pro} <- fetch_or_create_pro(ugg_pro["official_name"], team.id),
           attrs <-
             Map.merge(summoner_data, %{"platform_id" => ugg_pro["region_id"], "pro_id" => pro.id}),
           {:ok, summoner} <- update_or_create_summoner(attrs) do
        %{team: team, pro: pro, summoner: summoner}
      else
        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end

  def fetch_or_create_team(name) do
    case Repo.get_by(Team, name: name) do
      nil ->
        changeset = Team.changeset(%Team{}, %{name: name})
        Repo.insert(changeset)

      team ->
        {:ok, team}
    end
  end

  def fetch_or_create_pro(name, team_id) do
    case Repo.get_by(Pro, name: name, team_id: team_id) do
      nil ->
        %Pro{}
        |> Pro.changeset(%{name: name, team_id: team_id})
        |> Repo.insert()

      pro ->
        {:ok, pro}
    end
  end

  def update_or_create_summoner(attrs) do
    opts = [puuid: attrs["puuid"], platform_id: attrs["platform_id"]]

    case fetch_summoner(opts) do
      {:ok, summoner} ->
        update_summoner(summoner, attrs)

      {:error, :not_found} ->
        create_summoner(attrs)
    end
  end

  def create_summoner(attrs) do
    %Summoner{}
    |> Summoner.changeset(attrs)
    |> Repo.insert()
  end

  def update_summoner(summoner, attrs) do
    summoner
    |> Summoner.changeset(attrs)
    |> Repo.update()
  end

  def fetch_summoner(opts) do
    base_query = from(summoner in Summoner)
    query = Enum.reduce(opts, base_query, &reduce_summoner_opts/2)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      summoner -> {:ok, summoner}
    end
  end

  defp reduce_summoner_opts({:name, name}, query) do
    from summoner in query, where: summoner.name == ^name
  end

  defp reduce_summoner_opts({:puuid, puuid}, query) do
    from summoner in query, where: summoner.puuid == ^puuid
  end

  defp reduce_summoner_opts({:platform_id, platform_id}, query) do
    from summoner in query, where: summoner.platform_id == ^platform_id
  end

  defp reduce_summoner_opts({:is_pro?, true}, query) do
    from summoner in query, where: not is_nil(summoner.pro_id)
  end

  defp reduce_summoner_opts({:is_pro?, false}, query) do
    from summoner in query, where: is_nil(summoner.pro_id)
  end

  defp reduce_summoner_opts({k, v}, _query) do
    raise "not supported option #{inspect(k)} with value #{inspect(v)}"
  end
end
