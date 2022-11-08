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

  def fetch_champion_search_map() do
    GenServer.call(__MODULE__, :fetch_champion_search_map)
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
    request_and_cache_champions()
    request_and_cache_summoners()

    {:noreply, state}
  end

  defp request_and_cache_champions() do
    with {:ok, %{body: versions}} <- Api.fetch_versions(),
         last_version <- List.first(versions),
         {:ok, %{body: response}} <- Api.fetch_champions(last_version) do
      search_map_fn = fn {_, data} ->
        k = String.downcase(data["name"])
        v = String.to_integer(data["key"])
        {k, v}
      end

      search_map = create_data_map(response, search_map_fn)
      :ets.insert(:champions, {:search_map, search_map})

      response
      |> create_data_map()
      |> Enum.each(fn {key, img} ->
        :ets.insert(:champions, {{:img, key}, img})
      end)
    end
  end

  defp request_and_cache_summoners() do
    with {:ok, %{body: versions}} <- Api.fetch_versions(),
         last_version <- List.first(versions),
         {:ok, %{body: response}} <- Api.fetch_summoners(last_version) do
      response
      |> create_data_map()
      |> Enum.each(fn {key, img} ->
        :ets.insert(:summoners, {{:img, key}, img})
      end)
    end
  end

  defp image_kv({_, data}) do
    k = String.to_integer(data["key"])
    v = data["image"]["full"]
    {k, v}
  end

  defp create_data_map(response, fn_map \\ &image_kv/1) do
    response
    |> Map.get("data")
    |> Enum.map(fn_map)
    |> Map.new()
  end

  def handle_call({:fetch_champion_img, champion_key}, _from, state) do
    response = lookup(:champions, {:img, champion_key})
    {:reply, response, state}
  end

  def handle_call({:fetch_summoner_img, summoner_key}, _from, state) do
    response = lookup(:summoners, {:img, summoner_key})
    {:reply, response, state}
  end

  def handle_call(:fetch_champion_search_map, _from, state) do
    response = lookup(:champions, :search_map)
    {:reply, response, state}
  end

  defp lookup(table, key) do
    case :ets.lookup(table, key) do
      [{_, found}] -> {:ok, found}
      [] -> {:error, :not_found}
    end
  end
end
