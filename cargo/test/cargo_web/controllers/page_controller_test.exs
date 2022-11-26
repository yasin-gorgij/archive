defmodule CargoWeb.PageControllerTest do
  use CargoWeb.ConnCase
  import Cargo.AccountsFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "خوش آمدی"
  end

  test "provision page", %{conn: conn} do
    conn = get(conn, "/provision")
    assert html_response(conn, 200) =~ "ایجاد مدیر سیستم"
  end

  test "provision page redirects to home page", %{conn: conn} do
    admin_fixture()
    conn = get(conn, "/provision")
    assert html_response(conn, 302) =~ "You are being"
    assert html_response(conn, 302) =~ "<a href=\"/\">redirected</a>"
  end
end
