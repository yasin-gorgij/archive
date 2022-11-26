defmodule CargoWeb.UserControllerTest do
  use CargoWeb.ConnCase
  import Cargo.AccountsFixtures

  setup do
    %{user: user_fixture(), admin: admin_fixture()}
  end

  test "admin can access to list of users", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :index))

    assert html_response(conn, 200) =~ "لیست کاربران"
  end

  test "regular user can't access to list of users", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :index))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin calls new/2", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :new))

    assert html_response(conn, 200) =~ "کاربر جدید"
  end

  test "regular user calls new/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :new))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin calls create/2", %{conn: conn, admin: admin} do
    user_params = %{
      "name" => "Regular user",
      "family" => valid_family(),
      "mobile" => unique_mobile(),
      "email" => unique_email(),
      "password" => valid_password(),
      "role" => "user",
      "is_blocked" => "false"
    }

    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :create, %{"user" => user_params}))

    assert html_response(conn, 200) =~ "کاربر جدید"
  end

  test "regular user calls create/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :create, %{"user" => %{}}))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin calls show/2", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :show, admin.id))

    assert html_response(conn, 200) =~ "نمایش کاربر"
  end

  test "user calls show/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :show, user.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin calls edit/2", %{conn: conn, user: user, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :edit, user.id))

    assert html_response(conn, 200) =~ "ذخیره"
  end

  test "user calls edit/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :edit, user.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin calls update/2", %{conn: conn, user: user, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :update, user))

    assert html_response(conn, 200) =~ "ویرایش"
  end

  test "regular usr calls update/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :update, user))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin deletes a user", %{conn: conn, user: user, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :delete, user.id))

    assert html_response(conn, 200) =~ "نمایش کاربر"
  end

  test "regular user calls delete/2", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :delete, user.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin can't delete itself", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :delete, admin.id))

    assert html_response(conn, 200) =~ "نمایش کاربر"
  end

  test "admin blocks a user", %{conn: conn, user: user, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :block, user.id))

    assert html_response(conn, 302) =~ "redirected"
  end

  test "admin can't block itself", %{conn: conn, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :block, admin.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "regular user can't block", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :block, user.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end

  test "admin unblocks a user", %{conn: conn, user: user, admin: admin} do
    conn =
      conn
      |> log_in_user(admin)
      |> get(Routes.user_path(conn, :block, user.id))
      |> get(Routes.user_path(conn, :unblock, user.id))

    assert html_response(conn, 302) =~ "redirected"
  end

  test "regular user can't unblocks a user", %{conn: conn, user: user} do
    conn =
      conn
      |> log_in_user(user)
      |> get(Routes.user_path(conn, :unblock, user.id))

    assert html_response(conn, 403) =~ "Forbidden"
  end
end
