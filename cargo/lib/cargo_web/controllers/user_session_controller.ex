defmodule CargoWeb.UserSessionController do
  use CargoWeb, :controller

  alias Cargo.Accounts
  alias CargoWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user, user_params)

      {:error, _reason} ->
        render(conn, "new.html",
          error_message:
            gettext(
              "Invalid email/password, did not confirm your email or your account is blocked"
            )
        )
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
