defmodule ProbuildExWeb.GameLive.Index do
  use ProbuildExWeb, :live_view

  alias ProbuildEx.App
  alias ProbuildEx.Ddragon

  alias ProbuildExWeb.GameLive.SearchComponent

  @defaults %{
    page_title: "Listing games",
    changeset: App.Search.changeset(),
    search: %App.Search{},
    participants: [],
    loading?: true
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, @defaults)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if connected?(socket) do
        apply_action(socket, socket.assigns.live_action, params)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "filter",
        %{"search" => %{"platform_id" => platform_id, "search" => search}},
        socket
      ) do
    changeset =
      App.Search.changeset(socket.assigns.search, %{
        "platform_id" => platform_id,
        "search" => search
      })

    socket =
      case App.Search.validate(changeset) do
        {:ok, search} ->
          socket
          |> assign(changeset: changeset)
          |> assign(search: search)
          |> push_patch_index()

        {:error, _} ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("team_position", %{"position" => position}, socket) do
    changeset = App.Search.changeset(socket.assigns.search, %{"team_position" => position})

    socket =
      case App.Search.validate(changeset) do
        {:ok, search} ->
          socket
          |> assign(changeset: changeset)
          |> assign(search: search)
          |> push_patch_index()

        {:error, _} ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:query_pro_participants, opts}, socket) do
    participants = App.list_pro_participant_summoner(opts)

    socket =
      socket
      |> assign(participants: participants)
      |> assign(loading?: false)

    {:noreply, socket}
  end

  defp apply_action(socket, :index, params) do
    changeset = App.Search.changeset(socket.assigns.search, params)

    case App.Search.validate(changeset) do
      {:ok, search} ->
        opts = Map.from_struct(search)
        send(self(), {:query_pro_participants, opts})

        socket
        |> assign(changeset: changeset)
        |> assign(search: search)
        |> assign(loading?: true)

      {:error, _} ->
        socket
    end
  end

  defp push_patch_index(socket) do
    params = Map.from_struct(socket.assigns.search)
    push_patch(socket, to: Routes.game_index_path(socket, :index, params))
  end
end
