defmodule CargoWeb.UserController do
  use CargoWeb, :controller

  alias Cargo.Accounts
  alias Cargo.Accounts.User
  alias CargoWeb.Controllers.FallbackController

  defdelegate authorize(action, user, params), to: CargoWeb.Policy

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :index_user, current_user, nil) do
      :ok ->
        users = Accounts.list_users()
        render(conn, "index.html", users: users)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def new(conn, _params) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :new_user, current_user, nil) do
      :ok ->
        changeset = Accounts.change_user_registration(%User{})
        render(conn, "new.html", changeset: changeset)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def create(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :create_user, current_user, nil) do
      :ok ->
        create_user(conn, user_params)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :show_user, current_user, nil) do
      :ok ->
        user = Accounts.get_user!(id)
        render(conn, "show.html", user: user)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def edit(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :edit_user, current_user, nil) do
      :ok ->
        user = Accounts.get_user!(id)
        changeset = Accounts.change_user(user)
        render(conn, "edit.html", user: user, changeset: changeset)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :update_user, current_user, nil) do
      :ok ->
        user = Accounts.get_user!(id)

        case Accounts.update_user(user, user_params) do
          {:ok, user} ->
            conn
            |> put_flash(:info, gettext("User updated successfully."))
            |> redirect(to: Routes.user_path(conn, :show, user))

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "edit.html", user: user, changeset: changeset)
        end

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :delete_user, current_user, id) do
      :ok ->
        user = Accounts.get_user!(id)
        {:ok, _user} = Accounts.delete_user(user)

        conn
        |> put_flash(:info, gettext("User deleted successfully."))
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def block(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :block_user, current_user, id) do
      :ok ->
        user = Accounts.get_user!(id)
        {:ok, _user} = Accounts.block_user(user)

        conn
        |> put_flash(:info, gettext("User blocked successfully."))
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def unblock(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :unblock_user, current_user, nil) do
      :ok ->
        user = Accounts.get_user!(id)
        {:ok, _user} = Accounts.unblock_user(user)

        conn
        |> put_flash(:info, gettext("User unblocked successfully."))
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  defp create_user(conn, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(
          :info,
          gettext(
            "User created successfully. Please check your email for confirmation instructions."
          )
        )
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
