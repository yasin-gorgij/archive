defmodule Cargo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import CargoWeb.Gettext

  schema "users" do
    field :name, :string
    field :family, :string
    field :mobile, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :role, :string, null: false, default: "user"
    field :is_blocked, :boolean, default: false
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:name, :family, :mobile, :email, :password, :role, :is_blocked])
    |> validate_name()
    |> validate_family()
    |> validate_mobile()
    |> validate_email()
    |> validate_confirmation(:password, message: gettext("passwords do not match"))
    |> validate_password(opts)
    |> validate_role()
    |> validate_is_blocked()
  end

  def user_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :family, :mobile, :email, :role, :is_blocked])
    |> validate_name()
    |> validate_family()
    |> validate_mobile()
    |> validate_email()
    |> validate_role()
    |> validate_is_blocked()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[[:alpha:][:blank:]]+$/u,
      message: gettext("only characters and space are allowed")
    )
    |> validate_length(:name, max: 50, message: gettext("should be at most 50 characters"))
  end

  defp validate_family(changeset) do
    changeset
    |> validate_required([:family])
    |> validate_format(:family, ~r/^[[:alpha:][:blank:]]+$/u,
      message: gettext("only characters and space are allowed")
    )
    |> validate_length(:family, max: 50, message: gettext("should be at most 50 characters"))
  end

  defp validate_mobile(changeset) do
    changeset
    |> validate_required([:mobile])
    |> validate_format(:mobile, ~r/^[[:digit:]]+$/, message: gettext("must start with 0 (zero)"))
    |> validate_length(:mobile, is: 11, message: gettext("should be 11 digits"))
    |> unsafe_validate_unique(:mobile, Cargo.Repo)
    |> unique_constraint(:mobile)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: gettext("must have the @ sign and no spaces")
    )
    |> validate_length(:email, max: 160, message: gettext("should be at most 160 characters"))
    |> unsafe_validate_unique(:email, Cargo.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 10, message: gettext("should be at least 10 characters"))
    |> validate_length(:password, max: 80, message: gettext("should be at most 80 characters"))
    |> validate_format(:password, ~r/[a-z]/, message: gettext("at least one lower case character"))
    |> validate_format(:password, ~r/[A-Z]/, message: gettext("at least one upper case character"))
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: gettext("at least one digit or punctuation character")
    )
    |> maybe_hash_password(opts)
  end

  defp validate_role(changeset) do
    changeset
    |> validate_inclusion(:role, ["user", "admin"])
  end

  defp validate_is_blocked(changeset) do
    changeset
    |> validate_inclusion(:is_blocked, [true, false])
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the name.

  It requires the name to change otherwise an error is added.
  """
  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_name()
    |> case do
      %{changes: %{name: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :name, gettext("Name did not change"))
    end
  end

  @doc """
  A user changeset for changing the family.

  It requires the family to change otherwise an error is added.
  """
  def family_changeset(user, attrs) do
    user
    |> cast(attrs, [:family])
    |> validate_family()
    |> case do
      %{changes: %{family: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :family, gettext("Family did not change"))
    end
  end

  @doc """
  A user changeset for changing the mobile.

  It requires the mobile to change otherwise an error is added.
  """
  def mobile_changeset(user, attrs) do
    user
    |> cast(attrs, [:mobile])
    |> validate_mobile()
    |> case do
      %{changes: %{mobile: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :mobile, gettext("Mobile did not change"))
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, gettext("did not change"))
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: gettext("does not match password"))
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Cargo.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, gettext("is not valid"))
    end
  end

  @doc """
  Returns true if the user has confirmed their account, false otherwise
  """
  def is_confirmed?(user), do: user.confirmed_at != nil

  @doc """
  Returns true if the user has been blocked, false otherwise
  """
  def is_blocked?(user), do: user.is_blocked

  @doc """
  A user changeset for blocking/unblocking a user.
  """
  def block_user_changeset(user, should_block?) do
    user
    |> cast(%{is_blocked: should_block?}, [:is_blocked])
  end
end
