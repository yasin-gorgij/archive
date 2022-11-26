defmodule HouseInventory.Supervision.InventorySupervisor do
  @moduledoc false

  @spec start_child(String.t(), list()) :: {:ok, pid()}
  def start_child(inventory_name, items) do
    spec_of_child = %{
      id: HouseInventory.Service.InventoryService,
      start: {HouseInventory.Service.InventoryService, :start_link, [{inventory_name, items}]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(
           {:via, PartitionSupervisor, {PartitionedInventorySupervisor, self()}},
           spec_of_child
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end
end
