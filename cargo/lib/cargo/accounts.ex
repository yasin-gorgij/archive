defmodule Cargo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Cargo.Repo
  alias Cargo.Accounts.{User, UserNotifier, UserToken}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    cond do
      !User.valid_password?(user, password) -> {:error, :bad_username_or_password}
      !User.is_confirmed?(user) -> {:error, :not_confirmed}
      User.is_blocked?(user) -> {:error, :user_blocked}
      true -> {:ok, user}
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(%User{} = user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user name.

  ## Examples

      iex> change_user_name(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_name(%User{} = user, attrs \\ %{}) do
    User.name_changeset(%User{} = user, attrs)
  end

  @doc """
  Updates the user name.

  ## Examples

      iex> update_user_name(%User{} = user, %{name: "correct name"})
      {:ok, %User{}}

      iex> update_user_name(%User{} = user, %{name: "incorrect_name"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_name(%User{} = user, attrs) do
    user
    |> User.name_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user family.

  ## Examples

      iex> change_user_family(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_family(%User{} = user, attrs \\ %{}) do
    User.family_changeset(%User{} = user, attrs)
  end

  @doc """
  Updates the user family.

  ## Examples

      iex> update_user_family(%User{} = user, %{family: "correct family"})
      {:ok, %User{}}

      iex> update_user_family(%User{} = user, %{family: "incorrect_family"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_family(%User{} = user, attrs) do
    user
    |> User.family_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user mobile.

  ## Examples

      iex> change_user_mobile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_mobile(%User{} = user, attrs \\ %{}) do
    User.mobile_changeset(%User{} = user, attrs)
  end

  @doc """
  Updates the user mobile.

  ## Examples

      iex> update_user_mobile(%User{} = user, %{mobile: "09123456789"})
      {:ok, %User{}}

      iex> update_user_mobile(%User{} = user, %{mobile: "19123456789"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_mobile(%User{} = user, attrs) do
    user
    |> User.mobile_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(%User{} = user, attrs \\ %{}) do
    User.email_changeset(%User{} = user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(%User{} = user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(%User{} = user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(%User{} = user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(%User{} = user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(%User{} = user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(%User{} = user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_contexts_query(%User{} = user, [context])
    )
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(%User{} = user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} =
      UserToken.build_email_token(%User{} = user, "change:#{current_email}")

    Repo.insert!(user_token)

    UserNotifier.deliver_update_email_instructions(
      %User{} = user,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(%User{} = user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(%User{} = user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(%User{} = user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(%User{} = user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(%User{} = user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(%User{} = user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(%User{} = user, "confirm")
      Repo.insert!(user_token)

      UserNotifier.deliver_confirmation_instructions(
        %User{} = user,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(
      :tokens,
      UserToken.user_and_contexts_query(%User{} = user, ["confirm"])
    )
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(%User{} = user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(%User{} = user, "reset_password")
    Repo.insert!(user_token)

    UserNotifier.deliver_reset_password_instructions(
      %User{} = user,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(%User{} = user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(%User{} = user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(%User{} = user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(%User{} = user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Block a user and delete any tokens assigned to them
  """
  def block_user(%User{} = user) do
    {:ok, %{tokens: _tokens, user: user}} =
      user
      |> block_user_multi()
      |> Repo.transaction()

    {:ok, user}
  end

  defp block_user_multi(%User{} = user) do
    changeset = user |> User.block_user_changeset(true)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(%User{} = user, :all))
  end

  @doc """
  Unblock a user

  iex> unblock_user(%User{} = user)
      {:ok, %User{}}
  """
  def unblock_user(%User{} = user) do
    user
    |> User.block_user_changeset(false)
    |> Repo.update()
  end

  @doc """
  Returns the count of registered admins in database
  """
  def admin_count do
    Repo.one(from user in User, where: user.role == "admin", select: count(user))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.user_changeset(%User{} = user, attrs)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(%User{} = user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(%User{} = user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.user_changeset(attrs)
    |> Repo.update()
  end
end
