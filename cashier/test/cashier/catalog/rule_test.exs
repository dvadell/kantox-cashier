defmodule Cashier.Catalog.RuleTest do
  use Cashier.DataCase

  alias Cashier.Catalog.Rule

  @valid_attrs %{
    name: "Test Rule",
    code: "TEST_RULE",
    description: "A test promotional rule",
    rule_type: "BOGO",
    config: %{"something" => 1},
    conditions: %{"product_code" => "GR1", "min_quantity" => 1},
    priority: 10,
    active: true,
    start_date: ~U[2024-01-01 00:00:00Z],
    end_date: ~U[2024-12-31 23:59:59Z]
  }

  describe "changeset/2" do
    test "valid attributes create a valid changeset" do
      changeset = Rule.changeset(%Rule{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires name" do
      attrs = Map.delete(@valid_attrs, :name)
      changeset = Rule.changeset(%Rule{}, attrs)

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires code" do
      attrs = Map.delete(@valid_attrs, :code)
      changeset = Rule.changeset(%Rule{}, attrs)

      refute changeset.valid?
      assert %{code: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires description" do
      attrs = Map.delete(@valid_attrs, :description)
      changeset = Rule.changeset(%Rule{}, attrs)

      refute changeset.valid?
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires rule_type" do
      attrs = Map.delete(@valid_attrs, :rule_type)
      changeset = Rule.changeset(%Rule{}, attrs)

      refute changeset.valid?
      assert %{rule_type: ["can't be blank"]} = errors_on(changeset)
    end

    test "allows optional fields to be nil" do
      minimal_attrs = %{
        name: "Minimal Rule",
        code: "MINIMAL",
        description: "A minimal rule",
        rule_type: "DISCOUNT"
      }

      changeset = Rule.changeset(%Rule{}, minimal_attrs)
      assert changeset.valid?

      refute Map.has_key?(changeset.changes, :config)
      refute Map.has_key?(changeset.changes, :conditions)
      refute Map.has_key?(changeset.changes, :priority)
      refute Map.has_key?(changeset.changes, :active)
      refute Map.has_key?(changeset.changes, :start_date)
      refute Map.has_key?(changeset.changes, :end_date)
    end

    test "accepts config as a map" do
      changeset = Rule.changeset(%Rule{}, @valid_attrs)
      assert changeset.valid?
      assert changeset.changes.config == %{"something" => 1}
    end

    test "accepts conditions as a map" do
      changeset = Rule.changeset(%Rule{}, @valid_attrs)
      assert changeset.valid?
      assert changeset.changes.conditions == %{"product_code" => "GR1", "min_quantity" => 1}
    end

    test "accepts empty maps for config and conditions" do
      attrs = %{@valid_attrs | config: %{}, conditions: %{}}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
      assert changeset.changes.config == %{}
      assert changeset.changes.conditions == %{}
    end

    test "accepts priority as an integer" do
      attrs = %{@valid_attrs | priority: 5}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
      assert changeset.changes.priority == 5
    end

    test "accepts active as false" do
      attrs = %{@valid_attrs | active: false}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
      refute changeset.changes.active
    end

    test "accepts valid datetime for start_date" do
      start_date = ~U[2024-06-01 00:00:00Z]
      attrs = %{@valid_attrs | start_date: start_date}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
      assert changeset.changes.start_date == start_date
    end

    test "accepts valid datetime for end_date" do
      end_date = ~U[2024-12-31 23:59:59Z]
      attrs = %{@valid_attrs | end_date: end_date}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
      assert changeset.changes.end_date == end_date
    end

    test "allows nil for start_date and end_date" do
      attrs = %{@valid_attrs | start_date: nil, end_date: nil}
      changeset = Rule.changeset(%Rule{}, attrs)

      assert changeset.valid?
    end

    test "updates existing rule" do
      rule = %Rule{
        name: "Old Name",
        code: "OLD_CODE",
        description: "Old description",
        rule_type: "OLD_TYPE"
      }

      update_attrs = %{name: "New Name", description: "New description"}
      changeset = Rule.changeset(rule, update_attrs)

      assert changeset.valid?
      assert changeset.changes.name == "New Name"
      assert changeset.changes.description == "New description"

      refute Map.has_key?(changeset.changes, :code)
      refute Map.has_key?(changeset.changes, :rule_type)
    end

    test "handles string keys in attrs" do
      string_key_attrs = %{
        "name" => "String Key Rule",
        "code" => "STRING_KEY",
        "description" => "Uses string keys",
        "rule_type" => "BOGO"
      }

      changeset = Rule.changeset(%Rule{}, string_key_attrs)
      assert changeset.valid?
    end
  end

  describe "database constraints" do
    test "can insert valid rule into database" do
      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(@valid_attrs)
        |> Repo.insert()

      assert rule.id
      assert rule.name == @valid_attrs.name
      assert rule.code == @valid_attrs.code
    end

    test "can retrieve rule from database" do
      {:ok, inserted_rule} =
        %Rule{}
        |> Rule.changeset(@valid_attrs)
        |> Repo.insert()

      retrieved_rule = Repo.get(Rule, inserted_rule.id)

      assert retrieved_rule.name == @valid_attrs.name
      assert retrieved_rule.config == @valid_attrs.config
      assert retrieved_rule.conditions == @valid_attrs.conditions
    end

    test "defaults active to true when not provided" do
      attrs = Map.delete(@valid_attrs, :active)

      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(attrs)
        |> Repo.insert()

      assert rule.active == true
    end

    test "defaults priority to 0 when not provided" do
      attrs = Map.delete(@valid_attrs, :priority)

      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(attrs)
        |> Repo.insert()

      retrieved_rule = Repo.get(Rule, rule.id)
      assert retrieved_rule.priority == 0
    end

    test "persists config as JSONB" do
      complex_config = %{
        "product_code" => "TEST",
        "discount_percentage" => 20,
        "nested" => %{
          "key" => "value",
          "array" => [1, 2, 3]
        }
      }

      attrs = %{@valid_attrs | config: complex_config}

      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(attrs)
        |> Repo.insert()

      retrieved_rule = Repo.get(Rule, rule.id)
      assert retrieved_rule.config == complex_config
    end

    test "persists conditions as JSONB" do
      complex_conditions = %{
        "min_quantity" => 3,
        "customer_segments" => ["VIP", "PREMIUM"],
        "excluded_products" => ["PROD1", "PROD2"]
      }

      attrs = %{@valid_attrs | conditions: complex_conditions}

      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(attrs)
        |> Repo.insert()

      retrieved_rule = Repo.get(Rule, rule.id)
      assert retrieved_rule.conditions == complex_conditions
    end

    test "stores and retrieves datetime fields correctly" do
      {:ok, rule} =
        %Rule{}
        |> Rule.changeset(@valid_attrs)
        |> Repo.insert()

      retrieved_rule = Repo.get(Rule, rule.id)

      assert DateTime.compare(retrieved_rule.start_date, @valid_attrs.start_date) == :eq
      assert DateTime.compare(retrieved_rule.end_date, @valid_attrs.end_date) == :eq
    end
  end
end
