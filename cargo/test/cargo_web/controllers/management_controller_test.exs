defmodule CargoWeb.ManagementControllerTest do
  use CargoWeb.ConnCase
  import Cargo.AccountsFixtures

  setup do
    %{user: user_fixture(), admin: admin_fixture()}
  end

  test "admin access granted", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.management_path(conn, :index))

    assert html_response(conn, 200) =~ "کاربران"
  end

  test "user access denied", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.management_path(conn, :index))

    assert html_response(conn, 403) =~ "Forbidden"
  end
end
