defmodule Cashier.Repo.Migrations.AddInitialProductsAndRulesForProd do
  use Ecto.Migration

  def change do
    execute "DELETE FROM rules WHERE code IN ('GREEN_TEA_BOGO', 'STRAWBERRY_BULK', 'COFFEE_BULK')"
    execute "DELETE FROM products WHERE code IN ('GR1', 'SR1', 'CF1')"

    # Insert initial products
    execute """
    INSERT INTO products (code, name, price, inserted_at, updated_at) 
    VALUES 
      ('GR1', 'Green tea', 3.11, NOW(), NOW()),
      ('SR1', 'Strawberries', 5.00, NOW(), NOW()),
      ('CF1', 'Coffee', 11.23, NOW(), NOW())
    """

    # Insert initial rules
    execute """
    INSERT INTO rules (active, code, name, config, description, rule_type, conditions, inserted_at, updated_at) 
    VALUES 
      (
        true, 
        'GREEN_TEA_BOGO', 
        'Green Tea - Buy One Get One', 
        '{}'::jsonb,
        'Buy one green tea, get one for free', 
        'BOGO', 
        '{"product_code": "GR1"}'::jsonb,
        NOW(), 
        NOW()
      ),
      (
        true, 
        'STRAWBERRY_BULK', 
        'Strawberry Bulk Discount', 
        '{"price": "4.50"}'::jsonb,
        'Buy 3 or more strawberries for £4.50 each', 
        'BULK_DISCOUNT', 
        '{"min_quantity": 3, "product_code": "SR1"}'::jsonb,
        NOW(), 
        NOW()
      ),
      (
        true, 
        'COFFEE_BULK', 
        'Coffee Bulk Discount', 
        '{"price_fraction": 0.66666}'::jsonb,
        'Buy 3 or more coffees at 2/3 of the price', 
        'FRACTIONAL_PRICE', 
        '{"min_quantity": 3, "product_code": "CF1"}'::jsonb,
        NOW(), 
        NOW()
      )
    """
  end
end
