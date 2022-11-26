defmodule Cargo.Accounts.UserNotifier do
  alias Cargo.Mailer
  import Bamboo.Email

  @from_address "no-reply@user-deldutt.fandogh.cloud"

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.name},

    You can confirm your Cargo account by visiting the url below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.name},<br/></br/>
    You can confirm your Cargo account by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't create an account with us, please ignore this.
    """

    deliver(user.email, "Please confirm your Cargo account", text_body, html_body)
  end

  @doc """
  Deliver instructions to reset password account.
  """
  def deliver_reset_password_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.name},

    You can reset your Cargo password by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.name},<br/></br/>
    You can reset your Cargo password by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't request this change, please ignore this.
    """

    deliver(user.email, "Please confirm your Cargo account reset password", text_body, html_body)
  end

  @doc """
  Deliver instructions to update your e-mail.
  """
  def deliver_update_email_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.name},

    You can change your Cargo e-mail by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.name},<br/></br/>
    You can change your Cargo e-mail by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't request this change, please ignore this.
    """

    deliver(user.email, "Please confirm your Cargo account e-mail update", text_body, html_body)
  end

  defp deliver(to, subject, text_body, html_body) do
    email =
      new_email(
        to: to,
        from: @from_address,
        subject: subject,
        text_body: text_body,
        html_body: html_body
      )
      |> Mailer.deliver_later()

    {:ok, email}
  end
end
