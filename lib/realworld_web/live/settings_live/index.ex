defmodule RealworldWeb.SettingsLive.Index do
  use RealworldWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if current_user do
      form = AshPhoenix.Form.for_update(current_user, :update,
        actor: current_user,
        forms: [auto?: false]
      )
      |> to_form()

      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:form, form)
       |> assign(:page_title, "Settings")}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, form_params)
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> put_flash(:info, "Settings updated successfully")
         |> redirect(to: ~p"/")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/user/password/sign_out")}
  end
end
