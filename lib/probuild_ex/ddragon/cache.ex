defmodule ProbuildEx.Ddragon.Cache do
  use GenServer, restart: :transient

  alias ProbuildEx.Ddragon.Api

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def fetch_champion_img(key) do
    GenServer.call(__MODULE__, {:fetch_champion_img, key})
  end

  def fetch_summoner_img(key) do
    GenServer.call(__MODULE__, {:fetch_summoner_img, key})
  end

  def init(_) do
    opts = [
      :set,
      :named_table,
      :public,
      read_concurrency: true
    ]

    :ets.new(:champions, opts)
    :ets.new(:summoners, opts)

    {:ok, [], {:continue, :warmup}}
  end

  def handle_continue(:warmup, state) do
    request_and_cache(:champions)
    request_and_cache(:summoners)

    {:noreply, state}
  end

  defp request_and_cache(type) do
    with {:ok, %{body: versions}} <- Api.fetch_versions(),
         last_version <- List.first(versions),
         {:ok, %{body: response}} <- Api.fetch(type, last_version) do
      response
      |> create_images_map()
      |> Enum.each(fn {key, img} ->
        :ets.insert(type, {{:img, key}, img})
      end)
    end
  end

  defp create_images_map(response) do
    response
    |> Map.get("data")
    |> Enum.map(fn {_id, data} ->
      k = String.to_integer(data["key"])
      v = data["image"]["full"]
      {k, v}
    end)
    |> Map.new()
  end

  def handle_call({:fetch_champion_img, champion_key}, _from, state) do
    response = lookup(:champions, champion_key)
    {:reply, response, state}
  end

  def handle_call({:fetch_summoner_img, summoner_key}, _from, state) do
    response = lookup(:summoners, summoner_key)
    {:reply, response, state}
  end

  defp lookup(table, key) do
    case :ets.lookup(table, {:img, key}) do
      [{_, img}] -> {:ok, img}
      [] -> {:error, :not_found}
    end
  end
end
