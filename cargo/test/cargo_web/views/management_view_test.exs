defmodule CargoWeb.ManagementViewTest do
  use CargoWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders management page", %{conn: conn} do
    assert render_to_string(CargoWeb.ManagementView, "index.html", conn: conn) =~ "کاربران"
  end
end
