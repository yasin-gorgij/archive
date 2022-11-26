defmodule Cargo.AccountsTest do
  use Cargo.DataCase

  alias Cargo.Accounts
  alias Cargo.Accounts.{User, UserToken}
  import Cargo.AccountsFixtures

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      assert {:error, :bad_username_or_password} =
               Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()

      assert {:error, :bad_username_or_password} =
               Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "does not return the user if they have been blocked" do
      user = user_fixture()

      Accounts.block_user(user)

      assert {:error, :user_blocked} ==
               Accounts.get_user_by_email_and_password(user.email, valid_password())
    end

    test "does not return the user if their account has not been confirmed" do
      user = user_fixture(%{}, confirmed: false)

      assert {:error, :not_confirmed} =
               Accounts.get_user_by_email_and_password(user.email, valid_password())
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert {:ok, %User{id: ^id}} =
               Accounts.get_user_by_email_and_password(user.email, valid_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["باید از علامت @ استفاده کنید و فاصله‌ها را حذف کنید"],
               password: [
                 "حداقل باید یک عدد یا کاراکتر ویژه استفاده کنید",
                 "حداقل باید یک حرف بزرگ استفاده کنید",
                 "حداقل باید ۱۰ کاراکتر باشد"
               ]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "حداکثر باید ۱۶۰ کاراکتر باشد" in errors_on(changeset).email
      assert "حداکثر باید ۸۰ کاراکتر باشد" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      mobile = unique_mobile()
      email = unique_email()

      {:ok, user} =
        Accounts.register_user(%{
          name: "Regular user",
          family: valid_family(),
          mobile: mobile,
          email: email,
          password: valid_password()
        })

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email, :mobile, :family, :name]
    end

    test "allows fields to be set" do
      mobile = unique_mobile()
      email = unique_email()
      password = valid_password()

      changeset =
        Accounts.change_user_registration(%User{}, %{
          "name" => "Regular user",
          "family" => valid_family(),
          "mobile" => mobile,
          "email" => email,
          "password" => password
        })

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_name/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_name(%User{})
      assert changeset.required == [:name]
    end
  end

  describe "update_user_name/2" do
    setup do
      %{user: user_fixture()}
    end

    test "same name as before", %{user: user} do
      {:error, changeset} = Accounts.update_user_name(user, %{name: "Regular user"})

      assert %{name: ["نام تغییر نکرد"]} = errors_on(changeset)
    end

    test "invalid name", %{user: user} do
      {:error, changeset} = Accounts.update_user_name(user, %{name: invalid_name()})

      assert %{name: ["فقط از حروف و فاصله استفاده کنید"]} = errors_on(changeset)
    end

    test "valid name", %{user: user} do
      {:ok, user} = Accounts.update_user_name(user, %{name: valid_new_name()})

      assert user.name == valid_new_name()
    end
  end

  describe "change_user_family/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_family(%User{})
      assert changeset.required == [:family]
    end
  end

  describe "update_user_family/2" do
    setup do
      %{user: user_fixture()}
    end

    test "same family as before", %{user: user} do
      {:error, changeset} = Accounts.update_user_family(user, %{family: valid_family()})

      assert %{family: ["نام خانوادگی تغییر نکرد."]} = errors_on(changeset)
    end

    test "invalid family", %{user: user} do
      {:error, changeset} = Accounts.update_user_family(user, %{family: invalid_family()})

      assert %{family: ["فقط از حروف و فاصله استفاده کنید"]} = errors_on(changeset)
    end

    test "valid family", %{user: user} do
      {:ok, user} = Accounts.update_user_family(user, %{family: valid_new_family()})

      assert user.family == valid_new_family()
    end
  end

  describe "change_user_mobile/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_mobile(%User{})
      assert changeset.required == [:mobile]
    end
  end

  describe "update_user_mobile/2" do
    setup do
      %{user: user_fixture()}
    end

    test "same mobile as before", %{user: user} do
      {:error, changeset} = Accounts.update_user_mobile(user, %{mobile: user.mobile})

      assert %{mobile: ["موبایل تغییر نکرد"]} = errors_on(changeset)
    end

    test "invalid mobile", %{user: user} do
      {:error, changeset} = Accounts.update_user_mobile(user, %{mobile: invalid_mobile()})

      assert %{mobile: ["باید ۱۱ رقم باشد"]} = errors_on(changeset)
    end

    test "valid mobile", %{user: user} do
      mobile = unique_mobile()
      {:ok, user} = Accounts.update_user_mobile(user, %{mobile: mobile})

      assert user.mobile == mobile
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_password(), %{})
      assert %{email: ["هیچ تغییری وجود ندارد"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, valid_password(), %{email: "not valid"})

      assert %{email: ["باید از علامت @ استفاده کنید و فاصله‌ها را حذف کنید"]} =
               errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.apply_user_email(user, valid_password(), %{email: too_long})

      assert "حداکثر باید ۱۶۰ کاراکتر باشد" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()

      {:error, changeset} = Accounts.apply_user_email(user, valid_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, "invalid", %{email: unique_email()})

      assert %{current_password: ["نامعتبر است"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      result = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      IO.inspect(result, label: "RESULT: ")
      {1, nil} = result
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => valid_password()
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == valid_password()
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "حداقل باید یک عدد یا کاراکتر ویژه استفاده کنید",
                 "حداقل باید یک حرف بزرگ استفاده کنید",
                 "حداقل باید ۱۰ کاراکتر باشد"
               ],
               password_confirmation: ["رمزهای وارد شده مشابه هم نیستند"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_password(), %{password: too_long})

      assert "حداکثر باید ۸۰ کاراکتر باشد" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_password()})

      assert %{current_password: ["نامعتبر است"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_password(), %{
          password: valid_password()
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, valid_password())
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, valid_password(), %{
          password: valid_password()
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/1" do
    setup do
      user = user_fixture(%{}, confirmed: false)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the email with a valid token", %{user: user, token: token} do
      assert {:ok, confirmed_user} = Accounts.confirm_user(token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.confirmed_at != user.confirmed_at
      assert Repo.get!(User, user.id).confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "حداقل باید یک عدد یا کاراکتر ویژه استفاده کنید",
                 "حداقل باید یک حرف بزرگ استفاده کنید",
                 "حداقل باید ۱۰ کاراکتر باشد"
               ],
               password_confirmation: ["رمزهای وارد شده مشابه هم نیستند"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "حداکثر باید ۸۰ کاراکتر باشد" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: valid_password()})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, valid_password())
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: valid_password()})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "block_user/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)

      %{
        user: user,
        token: token
      }
    end

    test "sets the is_blocked flag to true and removes any tokens belonging to the user", %{
      user: user,
      token: token
    } do
      assert {:ok, user} = Accounts.block_user(user)

      assert user.is_blocked == true
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "unblock_user/1" do
    setup do
      {:ok, user} =
        user_fixture()
        |> Accounts.block_user()

      %{user: user}
    end

    test "sets the is_blocked flag to false", %{user: user} do
      assert {:ok, user} = Accounts.unblock_user(user)
      assert user.is_blocked == false
    end
  end

  describe "admin_count/0" do
    test "no admin user created, no Regular user created" do
      assert Accounts.admin_count() == 0
    end

    test "no admin user created, one Regular user created" do
      user = user_fixture()
      regular_user = Accounts.get_user!(user.id)

      assert Accounts.admin_count() == 0
      assert regular_user.role == user.role
    end

    test "admin user created" do
      admin = admin_fixture()
      admin_user = Accounts.get_user!(admin.id)

      assert Accounts.admin_count() == 1
      assert admin_user.role == admin.role
    end
  end

  test "delete user" do
    user = user_fixture()
    {:ok, deleted_user} = Accounts.delete_user(user)
    assert user != deleted_user
  end

  test "user changeset" do
    changeset = Accounts.change_user(%User{}, %{"name" => "Regular user"})
    assert changeset.changes.name == "Regular user"
  end

  test "user changeset without attribute" do
    changeset = Accounts.change_user(%User{})
    assert changeset.changes == %{}
  end

  test "update user name" do
    user = user_fixture()
    {:ok, updated_user} = Accounts.update_user(user, %{"name" => "New name"})
    assert updated_user.name == "New name"
  end
end
