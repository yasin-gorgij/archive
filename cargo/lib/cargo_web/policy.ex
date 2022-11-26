defmodule CargoWeb.Policy do
  @behaviour Bodyguard.Policy

  def authorize(action, %{role: "admin"} = current_user, params) do
    case action do
      :delete_user -> is_authorized(current_user.id, params)
      :block_user -> is_authorized(current_user.id, params)
      _ -> :ok
    end
  end

  def authorize(_action, _current_user, _params), do: :error

  defp is_authorized(current_user_id, params) do
    user_id = String.to_integer(params)

    if current_user_id != user_id do
      :ok
    else
      :error
    end
  end
end
