defmodule ProbuildExWeb.GameLive.Index do
  use ProbuildExWeb, :live_view

  import ProbuildExWeb.GameLive.DdragonComponent

  alias ProbuildEx.App
  alias ProbuildEx.Ddragon

  alias ProbuildExWeb.GameLive.SearchComponent
  alias ProbuildExWeb.GameLive.RowComponent

  alias Phoenix.PubSub

  @defaults %{
    page_title: "Listing games",
    update: "append",
    changeset: App.Search.changeset(),
    search: %App.Search{},
    page: %Scrivener.Page{},
    participants: [],
    loading?: true,
    load_more?: false,
    subscribed?: false
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, @defaults), temporary_assigns: [participants: []]}
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

  def handle_event("subscribe", _params, socket) do
    subscribed? =
      if socket.assigns.subscribed? do
        unsubscribe()
      else
        subscribe()
      end

    {:noreply,
     socket
     |> assign(:subscribed?, subscribed?)}
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
  def handle_event("load-more", _params, socket) do
    page = socket.assigns.page

    socket =
      if page.page_number < page.total_pages do
        opts = Map.from_struct(socket.assigns.search)
        send(self(), {:query_pro_participants, opts, page.page_number + 1})
        assign(socket, load_more?: true)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:query_pro_participants, opts}, socket) do
    socket =
      socket
      |> query_page(opts)
      |> assign(update: "replace")
      |> assign(loading?: false)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:query_pro_participants, opts, page_number}, socket) do
    socket =
      socket
      |> query_page(opts, page_number)
      |> assign(update: "append")
      |> assign(load_more?: false)

    {:noreply, socket}
  end

  def handle_info({:participant_id, participant_id}, socket) do
    opts =
      socket.assigns.search
      |> Map.from_struct()
      |> Map.put(:participant_id, participant_id)

    socket =
      case App.fetch_pro_participant(opts) do
        {:ok, participant} ->
          assign(socket, update: "prepend", participants: [participant])

        {:error, _err} ->
          socket
      end

    {:noreply, socket}
  end

  defp query_page(socket, opts, page_number \\ 1) do
    page = App.paginate_pro_participants(opts, page_number)

    socket
    |> assign(page: page)
    |> assign(participants: page.entries)
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

  defp subscribe() do
    case PubSub.subscribe(ProbuildEx.PubSub, "pro_participant:new") do
      :ok -> true
      {:error, _} -> false
    end
  end

  defp unsubscribe() do
    PubSub.unsubscribe(ProbuildEx.PubSub, "pro_participant:new")
    false
  end
end
