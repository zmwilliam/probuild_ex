defmodule ProbuildEx.App do
  import Ecto.Query

  alias ProbuildEx.Repo
  alias ProbuildEx.Games.Participant

  def list_pro_participant_summoner(_ \\ []) do
    query =
      from participant in Participant,
        left_join: game in assoc(participant, :game),
        left_join: summoner in assoc(participant, :summoner),
        left_join: op in assoc(participant, :opponent_participant),
        inner_join: pro in assoc(summoner, :pro),
        preload: [
          game: game,
          opponent_participant: op,
          summoner: {summoner, pro: pro}
        ],
        order_by: [desc: game.creation],
        limit: 20

    Repo.all(query)
  end
end
