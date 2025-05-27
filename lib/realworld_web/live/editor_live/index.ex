defmodule RealworldWeb.EditorLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Articles
  alias Realworld.Articles.Article

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(:current_user, socket.assigns[:current_user])
     |> assign(:form_tags, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    # Don't include tags in validation - handle them separately
    form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: false)
    {:noreply, assign(socket, form: to_form(form))}
  end

  def handle_event("update_tag_input", %{"tag" => %{"name" => tag_name}}, socket) do
    {:noreply, assign(socket, tag_input: tag_name)}
  end

  def handle_event("update_tag_input", %{"key" => _key, "value" => tag_name}, socket) do
    {:noreply, assign(socket, tag_input: tag_name)}
  end

  def handle_event("save", _params, socket) do
    # Add tags to form parameters right before submission
    current_params = AshPhoenix.Form.params(socket.assigns.form)
    params_with_tags = Map.put(current_params, "tags", socket.assigns.form_tags)
    
    # Validate form with tags included
    form_with_tags = AshPhoenix.Form.validate(socket.assigns.form, params_with_tags, errors: false)
    
    case AshPhoenix.Form.submit(form_with_tags) do
      {:ok, result} ->
        {:noreply, redirect(socket, to: ~p"/article/#{result.slug}")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  def handle_event("add_tag", %{"tag" => %{"name" => tag_name}}, socket) when tag_name != "" do
    current_tags = socket.assigns.form_tags
    
    # Check if tag already exists
    tag_exists = Enum.any?(current_tags, fn tag -> 
      get_tag_name(tag) == tag_name 
    end)

    unless tag_exists do
      new_tags = current_tags ++ [%{"name" => tag_name}]
      
      # Debug: Check the structure of new_tags
      IO.inspect(new_tags, label: "New tags being added")
      
      {:noreply, assign(socket, form_tags: new_tags, tag_input: "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_tag", _params, socket), do: {:noreply, socket}

  def handle_event("remove_tag", %{"name" => tag_name}, socket) do
    current_tags = socket.assigns.form_tags
    
    # Remove the tag with the specified name
    new_tags = Enum.reject(current_tags, fn tag ->
      get_tag_name(tag) == tag_name
    end)

    {:noreply, assign(socket, form_tags: new_tags)}
  end

  defp apply_action(socket, :new, _params) do
    form =
      AshPhoenix.Form.for_create(Article, :publish,
        actor: socket.assigns[:current_user],
        forms: [
          auto?: false
        ]
      )
      |> to_form

    assign(socket, form: form, page_title: "New Article", tag_input: "", form_tags: [])
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    case get_article_by_slug(slug) do
      {:ok, article} ->
        # Convert existing tags to the format expected by the form
        tags_for_form = Enum.map(article.tags, fn tag -> %{"name" => tag.name} end)
        
        form =
          AshPhoenix.Form.for_update(article, :update,
            actor: socket.assigns[:current_user],
            forms: [
              auto?: false
            ]
          )
          |> to_form

        assign(socket, form: form, page_title: "Edit Article", tag_input: "", form_tags: tags_for_form)

      _ ->
        redirect(socket, to: ~p"/")
    end
  end

  # Helper functions for tag management
  defp get_tag_name(tag) do
    case tag do
      %{"name" => name} -> name
      %{name: name} -> name
      _ -> nil
    end
  end

  # Helper functions for template
  def get_tag_display_name(tag) do
    case tag do
      %{"name" => name} -> name
      %{name: name} -> name
      name when is_binary(name) -> name
      _ -> ""
    end
  end

  defp get_article_by_slug(slug) do
    case Articles.get_article_by_slug(slug) do
      {:ok, article} -> 
        {:ok, Ash.load!(article, :tags)}
      error -> 
        error
    end
  end
end
