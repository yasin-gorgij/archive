defmodule Cargo.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Cargo.Accounts` context.
  """

  alias Cargo.Repo
  alias Cargo.Accounts.{User, UserToken}

  def unique_mobile() do
    digits =
      Enum.reduce(1..10, [], fn _x, list ->
        [Enum.random(0..9) | list]
      end)
      |> Enum.map(&to_string/1)
      |> Enum.join("")

    "0" <> digits
  end

  def unique_email, do: "user#{System.unique_integer()}@example.com"

  def valid_family, do: "My family"
  def valid_password, do: "Valid@Passw0rd"

  def valid_new_name, do: "My new name"
  def valid_new_family, do: "My new family"
  def valid_new_password, do: "Valid@NewPassw0rd"

  def invalid_name, do: "My 1nv@lid name"
  def invalid_family, do: "My 1nv@lid family"
  def invalid_mobile, do: "0912"
  def invalid_password, do: "inalidPassword"

  def admin_fixture(attrs \\ %{}, opts \\ []) do
    {:ok, admin} =
      attrs
      |> Enum.into(%{
        name: "Admin User",
        family: valid_family(),
        mobile: unique_mobile(),
        email: unique_email(),
        password: valid_password(),
        role: "admin",
        is_blocked: false
      })
      |> Cargo.Accounts.register_user()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_user_multi(admin))

    admin
  end

  def user_fixture(attrs \\ %{}, opts \\ []) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "Regular user",
        family: valid_family(),
        mobile: unique_mobile(),
        email: unique_email(),
        password: valid_password(),
        role: "user",
        is_blocked: false
      })
      |> Cargo.Accounts.register_user()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_user_multi(user))

    user
  end

  def extract_user_token(fun) do
    {:ok, {:ok, captured}} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end
end
