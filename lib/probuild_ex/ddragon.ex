defmodule ProbuildEx.Ddragon do
  @moduledoc """
  Convenience to access ddragon
  """

  alias ProbuildEx.Ddragon.Cache

  @ddragon_cdn "https://ddragon.leagueoflegends.com/cdn"

  def get_champion_image(game_version, champion_key) do
    case Cache.fetch_champion_img(champion_key) do
      {:ok, img} -> "#{@ddragon_cdn}/#{game_version}/img/champion/#{img}"
      {:error, _} -> nil
    end
  end

  def get_summoner_image(game_version, summoner_key) do
    case Cache.fetch_summoner_img(summoner_key) do
      {:ok, img} ->
        "#{@ddragon_cdn}/#{game_version}/img/spell/#{img}"

      {:error, _} ->
        nil
    end
  end

  def get_item_image(game_version, item_key)
  def get_item_image(_game_version, 0), do: nil

  def get_item_image(game_version, item_key) do
    "#{@ddragon_cdn}/#{game_version}/img/item/#{item_key}.png"
  end
end
