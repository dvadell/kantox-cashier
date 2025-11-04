defmodule Cashier.Catalog.ProductTest do
  use Cashier.DataCase, async: true

  alias Cashier.Catalog.Product

  describe "changeset/2" do
    @valid_attrs %{
      code: "GR1",
      name: "Green Tea",
      price: Decimal.new("3.11")
    }

    test "valid attributes create a valid changeset" do
      changeset = Product.changeset(%Product{}, @valid_attrs)

      assert changeset.valid?
      assert changeset.changes.code == "GR1"
      assert changeset.changes.name == "Green Tea"
      assert Decimal.eq?(changeset.changes.price, Decimal.new("3.11"))
    end

    test "code is required" do
      attrs = Map.delete(@valid_attrs, :code)
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).code
    end

    test "name is required" do
      attrs = Map.delete(@valid_attrs, :name)
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "price is required" do
      attrs = Map.delete(@valid_attrs, :price)
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).price
    end

    test "price must be greater than 0" do
      attrs = %{@valid_attrs | price: Decimal.new("0")}
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).price
    end

    test "price cannot be negative" do
      attrs = %{@valid_attrs | price: Decimal.new("-5.00")}
      changeset = Product.changeset(%Product{}, attrs)

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).price
    end

    test "accepts valid positive prices" do
      valid_prices = [
        Decimal.new("0.01"),
        Decimal.new("1.00"),
        Decimal.new("99.99"),
        Decimal.new("1000.50")
      ]

      for price <- valid_prices do
        attrs = %{@valid_attrs | price: price}
        changeset = Product.changeset(%Product{}, attrs)

        assert changeset.valid?, "Expected price #{price} to be valid"
      end
    end

    test "accepts string prices that can be converted to decimal" do
      attrs = %{@valid_attrs | price: "3.11"}
      changeset = Product.changeset(%Product{}, attrs)

      assert changeset.valid?
      assert Decimal.eq?(changeset.changes.price, Decimal.new("3.11"))
    end

    test "accepts integer prices" do
      attrs = %{@valid_attrs | price: 5}
      changeset = Product.changeset(%Product{}, attrs)

      assert changeset.valid?
      assert Decimal.eq?(changeset.changes.price, Decimal.new("5"))
    end

    test "ignores fields not in cast/3" do
      attrs = Map.put(@valid_attrs, :invalid_field, "should be ignored")
      changeset = Product.changeset(%Product{}, attrs)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :invalid_field)
    end

    test "updates existing product" do
      existing_product = %Product{
        code: "OLD",
        name: "Old Name",
        price: Decimal.new("10.00")
      }

      update_attrs = %{name: "Updated Name"}
      changeset = Product.changeset(existing_product, update_attrs)

      assert changeset.valid?
      assert changeset.changes.name == "Updated Name"
      # Unchanged fields should not be in changes
      refute Map.has_key?(changeset.changes, :code)
      refute Map.has_key?(changeset.changes, :price)
    end

    test "all fields missing returns multiple errors" do
      changeset = Product.changeset(%Product{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).code
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).price
    end
  end

  describe "schema fields" do
    test "has correct fields" do
      fields = Product.__schema__(:fields)

      assert :id in fields
      assert :code in fields
      assert :name in fields
      assert :price in fields
      assert :inserted_at in fields
      assert :updated_at in fields
    end

    test "code is a string" do
      assert Product.__schema__(:type, :code) == :string
    end

    test "name is a string" do
      assert Product.__schema__(:type, :name) == :string
    end

    test "price is a decimal" do
      assert Product.__schema__(:type, :price) == :decimal
    end
  end
end
