defmodule CargoWeb.PageController do
  use CargoWeb, :controller

  alias Cargo.Accounts
  alias Cargo.Accounts.User

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create_admin(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})

    case Accounts.admin_count() do
      0 -> render(conn, "create_admin.html", changeset: changeset)
      _ -> redirect(conn, to: Routes.page_path(conn, :index))
    end
  end
end
