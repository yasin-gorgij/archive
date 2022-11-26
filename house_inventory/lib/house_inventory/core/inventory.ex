defmodule HouseInventory.Core.Inventory do
  defstruct name: "", items: %{}

  @moduledoc false

  alias HouseInventory.Core.{Item, Inventory}

  @type item() :: %Item{}
  @type inventory() :: %Inventory{name: String.t(), items: map()}

  @spec new(%{name: String.t(), items: list()}) :: inventory()
  def new(%{name: name, items: items}) do
    items
    |> Enum.reduce(%Inventory{}, &add_item(&2, &1))
    |> Map.put(:name, name)
  end

  @spec add_item(inventory(), map()) :: inventory()
  def add_item(inventory, item) do
    items = Map.put(inventory.items, item.name, Item.new(item))

    %{inventory | items: items}
  end

  @spec item_quantity(inventory(), String.t()) :: number()
  def item_quantity(inventory, item_name) do
    inventory.items[item_name].quantity
  end

  @spec stock(inventory()) :: list()
  def stock(inventory) do
    inventory.items
    |> Map.values()
    |> Enum.map(&Map.from_struct/1)
  end

  @spec items(inventory()) :: list()
  def items(inventory) do
    Enum.map(inventory.items, fn {key, _value} -> key end)
  end

  @spec delete_item(inventory(), String.t()) :: inventory()
  def delete_item(inventory, item_name) do
    new_items = Map.delete(inventory.items, item_name)

    %{inventory | items: new_items}
  end

  @spec update_quantity(inventory(), String.t(), number()) :: inventory()
  def update_quantity(inventory, item_name, new_quantity) do
    update_inventory(inventory, item_name, %{name: item_name, quantity: new_quantity})
  end

  @spec rename_item(inventory(), String.t(), String.t()) :: inventory()
  def rename_item(inventory, current_name, new_name) do
    current_quantity = item_quantity(inventory, current_name)
    update_inventory(inventory, current_name, %{name: new_name, quantity: current_quantity})
  end

  @spec update_inventory(inventory(), String.t(), map()) :: inventory()
  defp update_inventory(inventory, current_item_name, updated_item) do
    inventory
    |> delete_item(current_item_name)
    |> add_item(updated_item)
  end
end
