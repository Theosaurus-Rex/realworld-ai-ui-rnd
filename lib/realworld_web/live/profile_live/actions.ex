defmodule RealworldWeb.ProfileLive.Actions do
  use Phoenix.Component

  attr :user, Realworld.Accounts.User, required: true
  attr :is_own_profile, :boolean, required: true
  attr :is_following, :boolean, required: true
  attr :settings_path, :string, required: true

  def actions(assigns) do
    ~H"""
    <div class="user-actions">
      <%= if @is_own_profile do %>
        <a class="btn btn-sm btn-outline-secondary action-btn" href={@settings_path}>
          <i class="ion-gear-a"></i>
          &nbsp;
          Edit Profile Settings
        </a>
      <% else %>
        <%= if @is_following do %>
          <button class="btn btn-sm btn-secondary action-btn" phx-click="unfollow-profile">
            <i class="ion-plus-round"></i>
            &nbsp;
            Unfollow <%= @user.username %>
          </button>
        <% else %>
          <button class="btn btn-sm btn-outline-secondary action-btn" phx-click="follow-profile">
            <i class="ion-plus-round"></i>
            &nbsp;
            Follow <%= @user.username %>
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end
end