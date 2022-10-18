defmodule ProbuildEx.Games.Summoner do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.Pro

  @required_attrs [:puuid, :platform_id, :name]
  @optional_attrs [:pro_id]

  schema "summoners" do
    field :name, :string

    field :platform_id, Ecto.Enum,
      values: [:br1, :eun1, :euw1, :jp1, :kr, :la1, :la2, :na1, :oc1, :ru, :tr1]

    field :puuid, :string

    belongs_to :pro, Pro

    timestamps()
  end

  @doc false
  def changeset(summoner, attrs) do
    summoner
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint([:puuid, :platform_id], name: "summoners_puuid_platform_id_index")
    |> foreign_key_constraint(:prod_id)
  end
end
