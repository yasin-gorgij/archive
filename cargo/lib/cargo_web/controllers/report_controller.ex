defmodule CargoWeb.ReportController do
  use CargoWeb, :controller

  alias Cargo.Accounts
  alias CargoWeb.Controllers.FallbackController

  defdelegate authorize(action, user, params), to: CargoWeb.Policy

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.ReportController, :index_report, current_user, nil) do
      :ok ->
        render(conn, "index.html")

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end

  def users(conn, _params) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.ReportController, :users_report, current_user, nil) do
      :ok ->
        users = Accounts.list_users()
        render(conn, "users.html", users: users)

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end
end
