defmodule CargoWeb.ManagementController do
  use CargoWeb, :controller

  alias CargoWeb.Controllers.FallbackController

  defdelegate authorize(action, user, params), to: CargoWeb.Policy

  def index(conn, _params) do
    current_user = conn.assigns.current_user

    case Bodyguard.permit(CargoWeb.UserController, :index_management, current_user, nil) do
      :ok ->
        render(conn, "index.html")

      {:error, :unauthorized} ->
        FallbackController.unauthorized(conn)
    end
  end
end
