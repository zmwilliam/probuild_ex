defmodule ProbuildEx.AppTest do
  use ExUnit.Case, async: true
  use ProbuildEx.DataCase

  import ProbuildEx.GamesFixtures

  alias ProbuildEx.Games.Participant
  alias ProbuildEx.{App, Games}
  alias ProbuildEx.GameDataFixtures

  describe "search" do
    test "validate/1 should validate query" do
      query = %{
        "search" => "faker",
        "platform_id" => "euw1",
        "team_position" => "MIDDLE"
      }

      changeset = App.Search.changeset(%App.Search{}, query)

      assert {:ok, _} = App.Search.validate(changeset)
    end

    test "validate/1 should ignore extra params" do
      query = %{"bob" => "bob"}
      changeset = App.Search.changeset(%App.Search{}, query)
      assert {:ok, _} = App.Search.validate(changeset)
    end

    test "validate/1 should error when value not in enum" do
      query = %{
        "search" => "faker",
        "platform_id" => "bob",
        "team_position" => "MIDDLE"
      }

      changeset = App.Search.changeset(%App.Search{}, query)
      assert {:error, changeset} = App.Search.validate(changeset)
      assert "is invalid" in errors_on(changeset).platform_id
    end
  end

  describe "list" do
    defp create_weiwei_game() do
      data = GameDataFixtures.get()
      %{ugg: weiwei_ugg, summoner_riot: weiwei_summoner} = GameDataFixtures.get_weiwei()

      {:ok, result} = Games.create_pro_complete(weiwei_ugg, weiwei_summoner)

      summoners_list =
        Enum.map(data.summoners_list, fn summoner ->
          if summoner["id"] == weiwei_summoner["id"] do
            result.summoner
          else
            summoner
          end
        end)

      Games.create_game_complete(data.platform_id, data.game_data, summoners_list)
    end

    test "list_pro_participant_summoner/1 should return participant matching the query" do
      create_weiwei_game()

      assert [%Participant{}] = App.list_pro_participant_summoner(%{search: "weiwei"})
      assert [%Participant{}] = App.list_pro_participant_summoner(%{platform_id: :kr})
      assert [%Participant{}] = App.list_pro_participant_summoner(%{team_position: :TOP})

      assert [] = App.list_pro_participant_summoner(%{search: "faker"})
      assert [] = App.list_pro_participant_summoner(%{platform_id: :euw1})
      assert [] = App.list_pro_participant_summoner(%{team_position: :MIDDLE})
    end
  end
end
