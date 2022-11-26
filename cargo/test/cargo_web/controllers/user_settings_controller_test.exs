defmodule CargoWeb.UserSettingsControllerTest do
  use CargoWeb.ConnCase, async: true

  alias Cargo.Accounts
  import Cargo.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings (change name form)" do
    test "update the user name", %{conn: conn} do
      new_name_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_name",
          "user" => %{
            "name" => valid_new_name()
          }
        })

      response = html_response(new_name_conn, 302)
      assert response =~ "You are being"
      assert response =~ "<a href=\"/users/settings\">redirected</a>"

      assert redirected_to(new_name_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_name_conn, :user_token) == get_session(conn, :user_token)
      assert get_flash(new_name_conn, :info) =~ "نام با موفقیت بروزرسانی شد."
    end

    test "does not update user name on invalid data", %{conn: conn} do
      old_name_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_name",
          "user" => %{
            "name" => invalid_name()
          }
        })

      response = html_response(old_name_conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
      assert response =~ "فقط از حروف و فاصله استفاده کنید"

      assert get_session(old_name_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change family form)" do
    test "update the user family", %{conn: conn} do
      new_family_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_family",
          "user" => %{
            "family" => valid_new_family()
          }
        })

      response = html_response(new_family_conn, 302)
      assert response =~ "You are being"
      assert response =~ "<a href=\"/users/settings\">redirected</a>"

      assert redirected_to(new_family_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_family_conn, :user_token) == get_session(conn, :user_token)
      assert get_flash(new_family_conn, :info) =~ "نام خانوادگی با موفقیت بروزرسانی شد."
    end

    test "does not update user family on invalid data", %{conn: conn} do
      old_family_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_family",
          "user" => %{
            "family" => invalid_family()
          }
        })

      response = html_response(old_family_conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
      assert response =~ "فقط از حروف و فاصله استفاده کنید"

      assert get_session(old_family_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change mobile form)" do
    test "update the user mobile", %{conn: conn} do
      new_mobile_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_mobile",
          "user" => %{
            "mobile" => unique_mobile()
          }
        })

      response = html_response(new_mobile_conn, 302)
      assert response =~ "You are being"
      assert response =~ "<a href=\"/users/settings\">redirected</a>"

      assert redirected_to(new_mobile_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_mobile_conn, :user_token) == get_session(conn, :user_token)
      assert get_flash(new_mobile_conn, :info) =~ "موبایل با موفقیت بروزرسانی شد."
    end

    test "does not update user mobile on invalid data", %{conn: conn} do
      old_mobile_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_mobile",
          "user" => %{
            "mobile" => invalid_mobile()
          }
        })

      response = html_response(old_mobile_conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
      assert response =~ "باید ۱۱ رقم باشد"

      assert get_session(old_mobile_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_password(),
          "user" => %{
            "password" => valid_password(),
            "password_confirmation" => valid_password()
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(new_password_conn, :info) =~ "رمز با موفقیت بروزرسانی شد."
      assert Accounts.get_user_by_email_and_password(user.email, valid_password())
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
      assert response =~ "حداقل باید ۱۰ کاراکتر باشد"
      assert response =~ "رمزهای وارد شده مشابه هم نیستند"
      assert response =~ "نامعتبر است"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_password(),
          "user" => %{"email" => unique_email()}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "لینک تایید به آدرس ایمیل جدید ارسال شده است."
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>تنظیمات</h1>"
      assert response =~ "باید از علامت @ استفاده کنید و فاصله‌ها را حذف کنید"
      assert response =~ "نامعتبر است"
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "ایمیل با موفقیت تغییر کرد."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)

      assert get_flash(conn, :error) =~
               "لینک تغییر ایمیل نامعتبر است یا یا مدت اعتبار آن به پایان رسیده."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)

      assert get_flash(conn, :error) =~
               "لینک تغییر ایمیل نامعتبر است یا یا مدت اعتبار آن به پایان رسیده."

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
