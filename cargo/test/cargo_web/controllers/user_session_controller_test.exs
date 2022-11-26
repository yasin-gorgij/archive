defmodule CargoWeb.UserSessionControllerTest do
  use CargoWeb.ConnCase, async: true

  import Cargo.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>ورود</h1>"
      assert response =~ "ورود</a>"
      assert response =~ "ثبت‌نام</a>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.name
      assert response =~ "تنظیمات</a>"
      assert response =~ "خروج</a>"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_cargo_web_user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>ورود</h1>"
      assert response =~ "ایمیل/رمز اشتباه است، ایمیل تایید نشده است یا حساب شما مسدود شده است"
    end

    test "emits error message when account is not confirmed", %{conn: conn} do
      user = user_fixture(%{}, confirmed: false)

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.name,
            "password" => valid_password(),
            "remember_me" => "true"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>ورود</h1>"

      assert response =~
               "ایمیل/رمز اشتباه است، ایمیل تایید نشده است یا حساب شما مسدود شده است"
    end

    test "emits error message when account is blocked", %{conn: conn} do
      {:ok, user} =
        user_fixture()
        |> Cargo.Accounts.block_user()

      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_password(),
            "remember_me" => "true"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>ورود</h1>"

      assert response =~
               "ایمیل/رمز اشتباه است، ایمیل تایید نشده است یا حساب شما مسدود شده است"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "خروج موفقیت آمیز بود."
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "خروج موفقیت آمیز بود."
    end
  end
end
