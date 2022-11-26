defmodule HouseInventory do
  alias HouseInventory.Service.InventoryService
  alias HouseInventory.Supervision.InventorySupervisor
  alias HouseInventory.Validation.Validator

  @spec start_inventory(String.t(), list()) :: {:ok, pid()} | {:error, term()}
  def start_inventory(name, items \\ []) do
    with {:ok, :valid_name} <- Validator.validate_name(name),
         {:ok, :valid_items} <- Validator.validate_items(items),
         {:error, :no_service} <- lookup_service(trim(name)) do
      pid =
        name
        |> trim()
        |> create_service(items)

      {:ok, pid}
    else
      {:error, :invalid_name} ->
        {:error, "Inventory name should be a non-empty string: #{inspect(name)}"}

      {:error, :invalid_items} ->
        {:error, "Invalid items #{inspect(items)}"}

      {:ok, :service, _pid} ->
        {:error, :already_exist}
    end
  end

  @spec stop_inventory(String.t()) :: {:ok, :success} | {:error, term()}
  def stop_inventory(name) do
    with {:ok, :valid_name} <- Validator.validate_name(name),
         {:ok, :service, _pid} <- lookup_service(trim(name)) do
      InventoryService.stop_inventory(name)
      {:ok, :success}
    else
      {:error, :invalid_name} ->
        {:error, "Inventory name should be a non-empty string: #{inspect(name)}"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(name)}"}
    end
  end

  @spec rename_inventory(String.t(), String.t()) :: {:ok, :success} | {:error, term()}
  def rename_inventory(current_name, new_name) do
    with {:ok, :valid_name} <- Validator.validate_name(current_name),
         {:ok, :valid_name} <- Validator.validate_name(new_name),
         {:ok, :service, _pid} <- lookup_service(trim(current_name)),
         {:error, :no_service} <- lookup_service(trim(new_name)) do
      with {:ok, stocks} <- stock(current_name),
           {:ok, :success} <- stop_inventory(current_name),
           {:ok, _pid} <- start_inventory(new_name, stocks) do
        {:ok, :success}
      else
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory name should be a non-empty string: #{inspect(current_name)} or #{inspect(new_name)} is invalid"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(current_name)}"}

      {:ok, :service, _pid} ->
        {:error,
         "Cann't rename to an existing inventory: #{inspect(current_name)} to #{inspect(new_name)}"}
    end
  end

  @spec add_item(String.t(), map()) :: {:ok, :success} | {:error, term()}
  def add_item(inventory_name, %{name: item_name, quantity: item_quantity} = item) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :valid_name} <- Validator.validate_name(item_name),
         {:ok, :valid_quantity} <- Validator.validate_quantity(item_quantity),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)),
         {:error, :no_item} <- lookup_item(trim(inventory_name), trim(item_name)) do
      {:ok, InventoryService.add_item(trim(inventory_name), item)}
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory or item name should be a non-empty string: #{inspect(inventory_name)} or #{inspect(item_name)} is invalid"}

      {:error, :invalid_quantity} ->
        {:error, "Quantity should be equal or greater than zero: #{inspect(item_quantity)}"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}

      {:ok, :item_exists} ->
        {:error, "Item already exist: #{inspect(item_name)}"}
    end
  end

  @spec item_quantity(String.t(), String.t()) :: {:ok, number()} | {:error, term()}
  def item_quantity(inventory_name, item_name) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :valid_name} <- Validator.validate_name(item_name),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)),
         {:ok, :item_exists} <- lookup_item(trim(inventory_name), trim(item_name)) do
      {:ok, InventoryService.item_quantity(trim(inventory_name), trim(item_name))}
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory or item name should be a non-empty string: #{inspect(inventory_name)} or #{inspect(item_name)} is invalid"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}

      {:error, :no_item} ->
        {:error, "Item doesn't exist: #{inspect(item_name)}"}
    end
  end

  @spec stock(String.t()) :: {:ok, list(map())} | {:error, term()}
  def stock(inventory_name) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)) do
      {:ok, InventoryService.stock(trim(inventory_name))}
    else
      {:error, :invalid_name} ->
        {:error, "Inventory name should be a non-empty string: #{inspect(inventory_name)}"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}
    end
  end

  @spec items(String.t()) :: {:ok, list(String.t())} | {:error, term()}
  def items(inventory_name) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)) do
      {:ok, InventoryService.items(trim(inventory_name))}
    else
      {:error, :invalid_name} ->
        {:error, "Inventory name should be a non-empty string: #{inspect(inventory_name)}"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}
    end
  end

  @spec delete_item(String.t(), String.t()) :: {:ok, :success} | {:error, term()}
  def delete_item(inventory_name, item_name) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :valid_name} <- Validator.validate_name(item_name),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)),
         {:ok, :item_exists} <- lookup_item(trim(inventory_name), trim(item_name)) do
      {:ok, InventoryService.delete_item(trim(inventory_name), trim(item_name))}
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory or item name should be a non-empty string: #{inspect(inventory_name)} or #{inspect(item_name)} is invalid"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}

      {:error, :no_item} ->
        {:error, "Item doesn't exist: #{inspect(item_name)}"}
    end
  end

  @spec update_quantity(String.t(), String.t(), number()) :: {:ok, :success} | {:error, term()}
  def update_quantity(inventory_name, item_name, new_item_quantity) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :valid_name} <- Validator.validate_name(item_name),
         {:ok, :valid_quantity} <- Validator.validate_quantity(new_item_quantity),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)),
         {:ok, :item_exists} <- lookup_item(trim(inventory_name), trim(item_name)) do
      {:ok,
       InventoryService.update_quantity(
         trim(inventory_name),
         trim(item_name),
         new_item_quantity
       )}
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory or item name should be a non-empty string: #{inspect(inventory_name)} or #{inspect(item_name)} is invalid"}

      {:error, :invalid_quantity} ->
        {:error, "Quantity should be equal or greater than zero: ${inspect(new_item_quantity)}"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}

      {:error, :no_item} ->
        {:error, "Item doesn't exist: #{inspect(item_name)}"}
    end
  end

  @spec rename_item(String.t(), String.t(), String.t()) :: {:ok, :success} | {:error, term()}
  def rename_item(inventory_name, current_name, new_name) do
    with {:ok, :valid_name} <- Validator.validate_name(inventory_name),
         {:ok, :valid_name} <- Validator.validate_name(current_name),
         {:ok, :valid_name} <- Validator.validate_name(new_name),
         {:ok, :service, _pid} <- lookup_service(trim(inventory_name)),
         {:ok, :item_exists} <- lookup_item(trim(inventory_name), trim(current_name)),
         {:error, :no_item} <- lookup_item(trim(inventory_name), trim(new_name)) do
      {:ok,
       InventoryService.rename_item(trim(inventory_name), trim(current_name), trim(new_name))}
    else
      {:error, :invalid_name} ->
        {:error,
         "Inventory or item name should be a non-empty string: #{inspect(inventory_name)}, #{inspect(current_name)} or #{inspect(new_name)} is invalid"}

      {:error, :no_service} ->
        {:error, "Inventory doesn't exist: #{inspect(inventory_name)}"}

      {:error, :no_item} ->
        {:error, "Item doesn't exist: #{inspect(current_name)}"}

      {:ok, :item_exists} ->
        {:error, "Can't rename to an existing item: #{inspect(new_name)}"}
    end
  end

  @spec create_service(String.t(), list()) :: pid()
  defp create_service(inventory_name, items) do
    inventory_name
    |> InventorySupervisor.start_child(items)
    |> elem(1)
  end

  @spec lookup_service(String.t()) :: {:ok, :service, pid()} | {:error, :no_service}
  defp lookup_service(service_name) do
    case Registry.lookup(ProcessRegistrySupervisor, {InventoryService, service_name}) do
      [{pid, _value}] -> {:ok, :service, pid}
      [] -> {:error, :no_service}
    end
  end

  @spec lookup_item(String.t(), String.t()) :: {:ok, :item_exists} | {:error, :no_item}
  defp lookup_item(inventory_name, item_name) do
    result =
      inventory_name
      |> items()
      |> elem(1)
      |> Enum.member?(item_name)

    case result do
      true -> {:ok, :item_exists}
      false -> {:error, :no_item}
    end
  end

  @spec trim(String.t()) :: String.t()
  defp trim(name), do: name |> String.trim()
end
