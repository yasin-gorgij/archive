defmodule CargoWeb.UserSettingsController do
  use CargoWeb, :controller

  alias Cargo.Accounts
  alias CargoWeb.UserAuth

  plug :assign_settings_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_name"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_name(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          gettext("Name updated successfully.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", name_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_family"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_family(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          gettext("Family updated successfully.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", family_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_mobile"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_mobile(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          gettext("Mobile updated successfully.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", mobile_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, user} ->
        Accounts.deliver_update_email_instructions(
          user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          gettext("A link to confirm your email change has been sent to the new address.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, gettext("Password updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Email changed successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, gettext("Email change link is invalid or it has expired."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_settings_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:name_changeset, Accounts.change_user_name(user))
    |> assign(:family_changeset, Accounts.change_user_family(user))
    |> assign(:mobile_changeset, Accounts.change_user_mobile(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
