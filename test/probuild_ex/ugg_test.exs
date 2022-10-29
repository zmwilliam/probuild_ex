defmodule ProbuildEx.UGGTest do
  use ExUnit.Case, async: true

  setup do
    pros = [
      %{
        "current_ign" => "tinowns",
        "current_team" => "LOUD",
        "league" => "CBLOL",
        "main_role" => "mid",
        "normalized_name" => "tinowns",
        "official_name" => "tinowns",
        "region_id" => "br1"
      },
      %{
        "current_ign" => "Hide on bush",
        "current_team" => "T1",
        "league" => "LCK",
        "main_role" => "mid",
        "normalized_name" => "faker",
        "official_name" => "Faker",
        "region_id" => "kr"
      }
    ]

    Tesla.Mock.mock(fn
      %{method: :get, url: "https://stats2.u.gg/pro/pro-list.json"} ->
        Tesla.Mock.json(pros)
    end)

    [pros: pros]
  end

  test "pro_list/0", %{pros: pros} do
    assert ^pros = ProbuildEx.UGG.pro_list()
  end
end
