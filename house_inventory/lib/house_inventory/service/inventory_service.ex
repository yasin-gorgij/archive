defmodule HouseInventory.Service.InventoryService do
  @moduledoc false

  alias HouseInventory.Core.Inventory
  alias HouseInventory.Boundary.Database

  use GenServer

  @spec start_link({String.t(), list()}) :: term()
  def start_link({inventory_name, items}) do
    GenServer.start_link(__MODULE__, {inventory_name, items}, name: via_tuple(inventory_name))
  end

  @spec stop_inventory(String.t()) :: term()
  def stop_inventory(inventory_name) do
    GenServer.stop(via_tuple(inventory_name), :normal)
  end

  @spec add_item(String.t(), map()) :: :success
  def add_item(inventory_name, %{name: _, quantity: _} = item) do
    GenServer.call(via_tuple(inventory_name), {:add_item, item})
  end

  @spec item_quantity(String.t(), String.t()) :: number()
  def item_quantity(inventory_name, item_name) do
    GenServer.call(via_tuple(inventory_name), {:item_quantity, item_name})
  end

  @spec stock(String.t()) :: list(map())
  def stock(inventory_name) do
    GenServer.call(via_tuple(inventory_name), {:stock})
  end

  @spec items(String.t()) :: list(String.t())
  def items(inventory_name) do
    GenServer.call(via_tuple(inventory_name), {:items})
  end

  @spec delete_item(String.t(), String.t()) :: :success
  def delete_item(inventory_name, item_name) do
    GenServer.call(via_tuple(inventory_name), {:delete_item, item_name})
  end

  @spec update_quantity(String.t(), String.t(), number()) :: :success
  def update_quantity(inventory_name, item_name, new_quantity) do
    GenServer.call(via_tuple(inventory_name), {:update_quantity, item_name, new_quantity})
  end

  @spec rename_item(String.t(), String.t(), String.t()) :: :success
  def rename_item(inventory_name, current_name, new_name) do
    GenServer.call(via_tuple(inventory_name), {:rename_item, current_name, new_name})
  end

  @impl true
  def init({inventory_name, items}) do
    {:ok, nil, {:continue, {:long_running_init, inventory_name, items}}}
  end

  @impl true
  def handle_continue({:long_running_init, inventory_name, items}, _inventory) do
    inventory =
      Database.get(inventory_name) || Inventory.new(%{name: inventory_name, items: items})

    {:noreply, inventory}
  end

  @impl true
  def handle_continue(_unknown_request, inventory) do
    {:noreply, inventory}
  end

  @impl true
  def handle_call({:add_item, item}, _from, inventory) do
    inventory = Inventory.add_item(inventory, item)

    {:reply, :success, inventory}
  end

  @impl true
  def handle_call({:item_quantity, item_name}, _from, inventory) do
    quantity = Inventory.item_quantity(inventory, item_name)

    {:reply, quantity, inventory}
  end

  @impl true
  def handle_call({:stock}, _from, inventory) do
    stock =
      inventory
      |> Inventory.stock()

    {:reply, stock, inventory}
  end

  @impl true
  def handle_call({:items}, _from, inventory) do
    items = Inventory.items(inventory)

    {:reply, items, inventory}
  end

  @impl true
  def handle_call({:delete_item, item_name}, _from, inventory) do
    inventory = Inventory.delete_item(inventory, item_name)

    {:reply, :success, inventory}
  end

  @impl true
  def handle_call({:update_quantity, item_name, new_item_quantity}, _from, inventory) do
    inventory = Inventory.update_quantity(inventory, item_name, new_item_quantity)

    {:reply, :success, inventory}
  end

  @impl true
  def handle_call({:rename_item, current_item_name, new_item_name}, _from, inventory) do
    inventory = Inventory.rename_item(inventory, current_item_name, new_item_name)

    {:reply, :success, inventory}
  end

  @impl true
  def handle_call(_unknown_request, _from, inventory) do
    {:reply, {:error, :unknown_request}, inventory}
  end

  @spec via_tuple(String.t()) :: term()
  defp via_tuple(inventory_name) do
    {:via, Registry, {ProcessRegistrySupervisor, {__MODULE__, inventory_name}}}
  end
end
