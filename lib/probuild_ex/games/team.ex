defmodule ProbuildEx.Games.Team do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
