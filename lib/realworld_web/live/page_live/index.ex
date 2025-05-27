defmodule RealworldWeb.PageLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles

  @impl true
  def mount(_params, _session, socket) do
    # Load recent articles for the homepage
    articles = Articles.list_articles()
    {:ok, assign(socket, articles: articles)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :index) do
    assign(socket, page_title: "Conduit")
  end
end
