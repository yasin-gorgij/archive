defmodule HouseInventory.Validation.Validator do
  @moduledoc false

  @spec validate_name(String.t()) :: {:ok, :valid_name} | {:error, :invalid_name}
  def validate_name(name) when is_binary(name) do
    name = name |> String.trim()

    with true <- String.length(name) > 0,
         true <- String.match?(name, ~r/^[[:alnum:][:space:]-_]+$/u) do
      {:ok, :valid_name}
    else
      false -> {:error, :invalid_name}
    end
  end

  def validate_name(_), do: {:error, :invalid_name}

  @spec validate_quantity(number()) :: {:ok, :valid_quantity} | {:error, :invalid_quantity}
  def validate_quantity(quantity) when is_number(quantity) do
    case quantity >= 0 do
      true -> {:ok, :valid_quantity}
      false -> {:error, :invalid_quantity}
    end
  end

  def validate_quantity(_), do: {:error, :invalid_quantity}

  @spec validate_items(list(map())) :: {:ok, :valid_items} | {:error, :invalid_items}
  def validate_items([%{name: name, quantity: quantity} | rest]) do
    with {:ok, :valid_name} <- validate_name(name),
         {:ok, :valid_quantity} <- validate_quantity(quantity) do
      validate_items(rest)
    else
      {:error, _reason} -> {:error, :invalid_items}
    end
  end

  def validate_items([]), do: {:ok, :valid_items}
  def validate_items(_), do: {:error, :invalid_items}
end
