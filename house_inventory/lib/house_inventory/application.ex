defmodule HouseInventory.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, [name: ProcessRegistrySupervisor, keys: :unique]},
      {PartitionSupervisor, [name: PartitionedInventorySupervisor, child_spec: DynamicSupervisor]},
      {HouseInventory.Repo, []}
    ]

    opts = [
      name: HouseInventory.MainSupervisor,
      strategy: :one_for_one
    ]

    Supervisor.start_link(children, opts)
  end
end
