defmodule ProbuildExWeb.GameLive.DdragonComponent do
  use Phoenix.Component

  alias ProbuildEx.Ddragon

  def champion(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-900">
      <img class="w-full" src={Ddragon.get_champion_image(@game_version, @champion_id)} />
    </div>
    """
  end

  def summoner(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-900">
      <img class="w-full" src={Ddragon.get_summoner_image(@game_version, @summoner_key)} />
    </div>
    """
  end

  def item(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-900">
      <img class="w-full" src={Ddragon.get_item_image(@game_version, @item_key)} />
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <img
      class={if not @load?, do: "invisible"}
      src="https://developer.riotgames.com/static/img/katarina.55a01cf0560a.gif"
    />
    """
  end
end
