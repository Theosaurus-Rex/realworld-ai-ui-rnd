defmodule RealworldWeb.ArticleLive.CommentsComponent do
  use RealworldWeb, :live_component

  alias AshPhoenix.Form
  alias Realworld.Articles.Comment

  def update(assigns, socket) do
    # ? should this go here or in the parent?
    form =
      Form.for_create(Comment, :create,
        as: "comment",
        forms: [auto?: true],
        actor: assigns[:current_user]
      )
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(form: form)

    {:ok, socket}
  end

  def handle_event(
        "post-comment",
        %{"comment" => %{"body" => body}},
        %{assigns: %{form: form, article_id: article_id}} = socket
      ) do
    case Form.submit(form, params: %{body: body, article_id: article_id}) do
      {:ok, _} ->
        {:noreply, assign(socket, form: form)}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  def handle_event(
        "delete-comment",
        %{"id" => comment_id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    comment_id
    |> Realworld.Articles.destroy_comment(actor: current_user)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p :if={!@current_user}>
        <a href={~p"/login"}>Sign in</a>
        or <a href={~p"/register"}>sign up</a>
        to add comments on this article.
      </p>

      <div :if={@current_user}>
        <.simple_form
          for={@form}
          class="card comment-form"
          phx-submit="post-comment"
          phx-target={@myself}
        >
          <div class="card-block">
            <%= textarea(@form, :body,
              class: "form-control",
              placeholder: "Write a comment...",
              rows: 3
            ) %>
            <%= error_tag(@form, :body) %>
          </div>
          <div class="card-footer">
            <img src={@current_user.image} class="comment-author-img" />
            <%= submit("Post Comment", class: "btn btn-sm btn-primary") %>
          </div>
        </.simple_form>
      </div>

      <%= for comment <- @comments do %>
        <div class="card">
          <div class="card-block">
            <p class="card-text"><%= comment.body %></p>
          </div>
          <div class="card-footer">
            <a href={~p"/profile/#{comment.user.username}"} class="comment-author">
              <img src={comment.user.image} class="comment-author-img" />
            </a>
            &nbsp;
            <a href={~p"/profile/#{comment.user.username}"} class="comment-author">
              <%= comment.user.username %>
            </a>
            <span class="date-posted">
              <%= Calendar.strftime(comment.created_at, "%B %d, %Y") %>
            </span>
            <span :if={@current_user && comment.user.id == @current_user.id} class="mod-options">
              <i
                class="ion-trash-a"
                phx-click="delete-comment"
                phx-value-id={comment.id}
                phx-target={@myself}
              >
              </i>
            </span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
