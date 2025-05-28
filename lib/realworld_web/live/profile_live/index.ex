defmodule RealworldWeb.ProfileLive.Index do
  use RealworldWeb, :live_view

  import RealworldWeb.ProfileLive.Actions, only: [actions: 1]

  alias Realworld.{Accounts, Articles, Profiles}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  defp apply_action(socket, :profile, %{"username" => username}) do
    case get_user_by_username(username, socket.assigns[:current_user]) do
      {:ok, user} ->
        socket
        |> assign(:user, user)
        |> assign(:current_tab, :my_articles)
        |> assign(:selected_tag, nil)
        |> assign(:is_own_profile, is_own_profile?(socket.assigns[:current_user], user))
        |> assign(:following, follows?(socket.assigns[:current_user], user))
        |> assign(:loading, true)
        |> assign(:page_title, "@#{user.username}")
        |> load_articles()

      {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} ->
        socket
        |> put_flash(:error, "User not found")
        |> redirect(to: ~p"/")

      _ ->
        socket
        |> put_flash(:error, "Unable to load profile")
        |> redirect(to: ~p"/")
    end
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab_atom = String.to_atom(tab)
    
    {:noreply,
     socket
     |> assign(:current_tab, tab_atom)
     |> assign(:selected_tag, nil)
     |> assign(:page_title, "@#{socket.assigns.user.username}")
     |> assign(:loading, true)
     |> load_articles()}
  end

  def handle_event("filter_by_tag", %{"tag" => tag_name}, socket) do
    {:noreply,
     socket
     |> assign(:current_tab, :tag)
     |> assign(:selected_tag, tag_name)
     |> assign(:page_title, "##{tag_name}")
     |> assign(:loading, true)
     |> load_articles()}
  end

  def handle_event("follow-profile", _, %{assigns: %{current_user: current_user, user: user}} = socket) do
    case Profiles.follow(user.id, actor: current_user) do
      {:ok, follow} ->
        {:noreply, assign(socket, following: follow)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("unfollow-profile", _, %{assigns: %{current_user: current_user, user: user}} = socket) do
    case Profiles.unfollow(user.id, return_destroyed?: true, actor: current_user) do
      {:ok, _} ->
        {:noreply, assign(socket, following: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("follow-profile", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("unfollow-profile", _, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("favorite-article", %{"slug" => slug}, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:noreply, redirect(socket, to: ~p"/login")}
      
      user ->
        case Articles.get_article_by_slug(slug, actor: user) do
          {:ok, article} ->
            case Articles.favorite(article.id, actor: user) do
              {:ok, _} ->
                {:noreply, load_articles(socket)}
              
              {:error, _} ->
                {:noreply, socket}
            end
          
          {:error, _} ->
            {:noreply, socket}
        end
    end
  end

  def handle_event("unfavorite-article", %{"slug" => slug}, socket) do
    case socket.assigns[:current_user] do
      nil ->
        {:noreply, redirect(socket, to: ~p"/login")}
      
      user ->
        case Articles.get_article_by_slug(slug, actor: user) do
          {:ok, article} ->
            case Articles.unfavorite(article.id, return_destroyed?: true, actor: user) do
              {:ok, _} ->
                {:noreply, load_articles(socket)}
              
              {:error, _} ->
                {:noreply, socket}
            end
          
          {:error, _} ->
            {:noreply, socket}
        end
    end
  end

  defp get_user_by_username(username, current_user) do
    Accounts.get_user_by_username(username, actor: current_user)
  end

  defp load_articles(socket) do
    filter = case socket.assigns.current_tab do
      :my_articles -> %{author: socket.assigns.user.id}
      :favorited_articles -> %{favourited: socket.assigns.user.id}
      :tag -> 
        case socket.assigns[:selected_tag] do
          nil -> %{}
          tag -> %{tag: tag}
        end
      _ -> %{author: socket.assigns.user.id}
    end

    case Articles.list_articles(%{filter: filter}, actor: socket.assigns[:current_user]) do
      {:ok, %{results: articles}} ->
        assign(socket, articles: articles, loading: false)
      
      {:error, _reason} ->
        assign(socket, articles: [], loading: false)
    end
  end

  defp is_own_profile?(nil, _), do: false
  defp is_own_profile?(current_user, user), do: current_user.id == user.id

  defp follows?(nil, _), do: nil
  defp follows?(current_user, user) do
    case Profiles.following(user.id, actor: current_user) do
      {:ok, follow} -> follow
      _ -> nil
    end
  end

  # Helper functions for the template
  def format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  def is_favorited?(_article, user) when is_nil(user), do: false
  def is_favorited?(article, _user) do
    article.is_favorited || false
  end

  def favorite_count(article) do
    article.favorites_count || 0
  end

  def tab_class(current_tab, tab_name) do
    if current_tab == tab_name do
      "nav-link active"
    else
      "nav-link"
    end
  end
end