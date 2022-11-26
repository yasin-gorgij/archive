defmodule CargoWeb.UserRegistrationControllerTest do
  use CargoWeb.ConnCase, async: true

  import Cargo.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>ثبت‌نام</h1>"
      assert response =~ "ورود</a>"
      assert response =~ "ثبت‌نام</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and DOES NOT log the user in", %{conn: conn} do
      mobile = unique_mobile()
      email = unique_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "name" => "Regular user",
            "family" => valid_family(),
            "mobile" => mobile,
            "email" => email,
            "password" => valid_password(),
            "password_confirmation" => valid_password()
          }
        })

      refute get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/users/log_in"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")

      assert get_flash(conn, :info) ==
               "کاربر با موفقیت ایجاد شد. برای تایید حساب به ایمیل خود مراجعه کنید."
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "email" => "with spaces",
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>ثبت‌نام</h1>"
      assert response =~ "باید از علامت @ استفاده کنید و فاصله‌ها را حذف کنید"

      assert response =~
               "حداقل ۱۰ کاراکتر باشد که شامل حروف کوچک، حروف بزرگ و عدد یا کاراکتر خاص باشد"

      assert response =~ "رمزهای وارد شده مشابه هم نیستند"
    end
  end
end
