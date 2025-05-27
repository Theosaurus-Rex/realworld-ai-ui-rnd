defmodule RealworldWeb.PageLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles
  alias RealworldWeb.LiveHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(:current_user, socket.assigns[:current_user])
     |> assign(:current_tab, :global)
     |> assign(:loading, true)
     |> assign(:selected_tag, nil)
     |> assign(:page_title, "Conduit")
     |> load_articles()
     |> load_popular_tags()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab_atom = String.to_atom(tab)
    
    {:noreply,
     socket
     |> assign(:current_tab, tab_atom)
     |> assign(:selected_tag, nil)
     |> assign(:loading, true)
     |> load_articles()}
  end

  def handle_event("favorite_article", %{"slug" => slug}, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to favorite articles")}
      
      user ->
        case Articles.favorite_article(slug, user) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Article favorited!")
             |> load_articles()}
          
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to favorite article")}
        end
    end
  end

  def handle_event("unfavorite_article", %{"slug" => slug}, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in")}
      
      user ->
        case Articles.unfavorite_article(slug, user) do
          {:ok, _} ->
            {:noreply, 
             socket
             |> put_flash(:info, "Article unfavorited!")
             |> load_articles()}
          
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to unfavorite article")}
        end
    end
  end

  def handle_event("filter_by_tag", %{"tag" => tag_name}, socket) do
    {:noreply,
     socket
     |> assign(:current_tab, :tag)
     |> assign(:selected_tag, tag_name)
     |> assign(:loading, true)
     |> load_articles()}
  end

  defp load_articles(socket) do
    # Build filter based on current tab
    filter = case socket.assigns.current_tab do
      :global -> %{}
      :feed -> %{}  # For personal feed, we use private_feed? parameter instead
      :tag -> 
        case socket.assigns[:selected_tag] do
          nil -> %{}
          tag -> %{tag: tag}
        end
      _ -> %{}
    end
    
    # Determine if this is a private feed request
    private_feed? = socket.assigns.current_tab == :feed

    # Pass arguments as a map, then options
    case Articles.list_articles(
      %{filter: filter, private_feed?: private_feed?},
      actor: socket.assigns[:current_user]
    ) do
      {:ok, %{results: articles}} ->
        # Articles should already have associations loaded by the preparation
        assign(socket, articles: articles, loading: false)
      
      {:error, _reason} ->
        assign(socket, articles: [], loading: false)
    end
  end

  defp load_popular_tags(socket) do
    # Get all tags - we'll implement get_popular_tags later
    case Articles.list_tags() do
      {:ok, tags} ->
        # Take the first 10 tags as "popular" for now
        popular = Enum.take(tags, 10)
        assign(socket, popular_tags: popular)
      
      {:error, _} ->
        assign(socket, popular_tags: [])
    end
  end

  # Helper functions for the template
  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  def is_favorited?(_article, user) when is_nil(user), do: false
  def is_favorited?(article, _user) do
    # Use the calculated field from the Article resource
    article.is_favorited || false
  end

  def favorite_count(article) do
    article.favorites_count || 0
  end

  def user_logged_in?(assigns) do
    !is_nil(assigns[:current_user])
  end

  def tab_class(current_tab, tab_name) do
    if current_tab == tab_name do
      "nav-link active"
    else
      "nav-link"
    end
  end
end
