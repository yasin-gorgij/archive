defmodule CoreTest do
  use ExUnit.Case

  alias HouseInventory.Core.{Item, Inventory}

  @item_name "Rice"
  @item_quantity 5
  @raw_item %{name: @item_name, quantity: @item_quantity}

  @inventory_name "house"
  @inventory %Inventory{name: @inventory_name, items: %{}}

  describe("Item:") do
    test "create new item" do
      assert %Item{name: @item_name, quantity: @item_quantity} ==
               Item.new(%{name: @item_name, quantity: @item_quantity})
    end
  end

  describe "Inventory" do
    test "create new inventory without any item" do
      assert @inventory == Inventory.new(%{name: @inventory_name, items: []})
    end

    test "create new inventory with one item" do
      assert %Inventory{
               name: @inventory_name,
               items: %{@item_name => %Item{name: @item_name, quantity: @item_quantity}}
             } ==
               Inventory.new(%{name: @inventory_name, items: [@raw_item]})
    end

    test "add an item to inventory" do
      assert %Inventory{
               name: @inventory_name,
               items: %{@item_name => %Item{name: @item_name, quantity: @item_quantity}}
             } ==
               Inventory.add_item(@inventory, @raw_item)
    end

    test "get quantity of an item from inventory" do
      test_inventory = Inventory.add_item(@inventory, @raw_item)

      assert @item_quantity == Inventory.item_quantity(test_inventory, @item_name)
    end

    test "get list of inventory stock" do
      stock =
        @inventory
        |> Inventory.add_item(@raw_item)
        |> Inventory.stock()

      assert [@raw_item] == stock
    end

    test "get list of inventory items" do
      items =
        @inventory
        |> Inventory.add_item(@raw_item)
        |> Inventory.items()

      assert [@item_name] == items
    end

    test "delete an item from inventory" do
      test_inventory =
        @inventory
        |> Inventory.add_item(@raw_item)
        |> Inventory.delete_item(@item_name)

      assert %{} == test_inventory.items
    end

    test "update item quantity in inventory" do
      quantity =
        @inventory
        |> Inventory.add_item(@raw_item)
        |> Inventory.update_quantity(@item_name, 500)
        |> Inventory.item_quantity(@item_name)

      refute 500 == @item_quantity
      assert 500 == quantity
    end

    test "rename an item in inventory" do
      name =
        @inventory
        |> Inventory.add_item(@raw_item)
        |> Inventory.rename_item(@item_name, "Handwash")
        |> Inventory.items()
        |> List.first()

      refute "Handwash" == @item_name
      assert "Handwash" == name
    end
  end
end
