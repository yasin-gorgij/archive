defmodule HouseInventory.Core.Item do
  defstruct name: "", quantity: -1

  @moduledoc false

  alias HouseInventory.Core.Item

  @type item() :: %Item{name: String.t(), quantity: number()}

  @spec new(%{name: String.t(), quantity: number()}) :: item()
  def new(%{name: name, quantity: quantity}) do
    %Item{name: name, quantity: quantity}
  end
end
