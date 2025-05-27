defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles
  alias Realworld.Articles.Article

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", _params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form) do
      {:ok, result} ->
        {:noreply, redirect(socket, to: "/article/#{result.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event("add_tag", %{"tag" => %{"name" => tag_name}}, socket) when tag_name != "" do
    form = socket.assigns.form
    current_tags = AshPhoenix.Form.value(form, :tags) || []
    
    # Check if tag already exists
    tag_exists = Enum.any?(current_tags, fn tag -> 
      (is_map(tag) && Map.get(tag, :name) == tag_name) ||
      (is_binary(tag) && tag == tag_name)
    end)
    
    unless tag_exists do
      new_tags = current_tags ++ [%{name: tag_name}]
      form = AshPhoenix.Form.validate(form, %{"tags" => new_tags}, errors: false)
      {:noreply, assign(socket, form: form)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_tag", _params, socket), do: {:noreply, socket}

  def handle_event("remove_tag", %{"path" => path}, socket) do
    form = socket.assigns.form
    current_tags = AshPhoenix.Form.value(form, :tags) || []
    
    # Extract index from path (e.g., "tags[1]" -> 1)
    index = 
      path
      |> String.replace(~r/tags\[(\d+)\]/, "\\1")
      |> String.to_integer()
    
    new_tags = List.delete_at(current_tags, index)
    form = AshPhoenix.Form.validate(form, %{"tags" => new_tags}, errors: false)
    {:noreply, assign(socket, form: form)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      AshPhoenix.Form.for_create(Article, :publish,
        actor: socket.assigns.current_user,
        forms: [
          auto?: true
        ]
      )
      |> to_form

    assign(socket, form: form, page_title: "New Article")
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    case get_article_by_slug(slug) do
      {:ok, article} ->
        form =
          AshPhoenix.Form.for_update(article, :update,
            actor: socket.assigns.current_user,
            forms: [
              auto?: true
            ]
          )
          |> to_form

        assign(socket, form: form, page_title: "Edit Article")

      _ ->
        redirect(socket, to: ~p"/")
    end
  end

  defp get_article_by_slug(slug) do
    slug |> Articles.get_article_by_slug() |> Ash.load(:tags)
  end
end
