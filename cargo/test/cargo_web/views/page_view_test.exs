defmodule CargoWeb.PageViewTest do
  use CargoWeb.ConnCase, async: true

  alias Cargo.Accounts
  alias Cargo.Accounts.User

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders index.html" do
    assert render_to_string(CargoWeb.PageView, "index.html", []) =~ "خوش آمدی"
  end

  test "renders create_admin.html", %{conn: conn} do
    changeset = Accounts.change_user_registration(%User{})

    assert render_to_string(CargoWeb.PageView, "create_admin.html",
             conn: conn,
             changeset: changeset
           ) =~ "ایجاد مدیر سیستم"
  end
end
