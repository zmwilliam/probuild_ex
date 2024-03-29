defmodule ProbuildEx.Games.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.{Game, Participant, Summoner}

  @positions [:UTILITY, :TOP, :JUNGLE, :MIDDLE, :BOTTOM]

  @required_attrs [
    :assists,
    :champion_id,
    :deaths,
    :gold_earned,
    :items,
    :kills,
    :summoners,
    :team_position,
    :team_id,
    :win,
    :game_id,
    :summoner_id
  ]

  @optional_attrs [:opponent_participant_id]

  schema "participants" do
    field :assists, :integer
    field :champion_id, :integer
    field :deaths, :integer
    field :gold_earned, :integer
    field :items, {:array, :integer}
    field :kills, :integer
    field :summoners, {:array, :integer}
    field :team_id, :integer
    field :team_position, Ecto.Enum, values: @positions
    field :win, :boolean, default: false

    belongs_to :game, Game
    belongs_to :summoner, Summoner
    belongs_to :opponent_participant, Participant

    timestamps()
  end

  @doc false
  def changeset(participant \\ %__MODULE__{}, attrs) do
    participant
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:summoner_id)
    |> foreign_key_constraint(:opponent_participant_id)
  end

  def get_positions(), do: @positions
end
