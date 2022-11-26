defmodule CargoWeb.Controllers.FallbackController do
  use CargoWeb, :controller

  def unauthorized(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(CargoWeb.ErrorView)
    |> render(:"403")
  end
end
