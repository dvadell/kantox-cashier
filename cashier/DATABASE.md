# Product
The products table stores products to be sold by the cashier

## Table Schema

| Column | Type | Description |
|--------|------|----------|
| `code` | string | Primary key |
| `name` | string | Human-readable name for the rule |
| `price` | decimal | Price of one item |
| `inserted_at` | utc_datetime | Record creation timestamp |
| `updated_at` | utc_datetime | Last update timestamp |



# Rules
The rules table stores promotional rules and discount configurations

## Table Schema

| Column | Type | Description |
|--------|------|----------|
| `id` | bigint | Primary key |
| `name` | string | Human-readable name for the rule |
| `code` | string | Unique identifier for the rule |
| `description` | text | Detailed explanation of what the rule does |
| `rule_type` | string | Type of plugin to handle the promotion  |
| `config` | map (JSONB) | Configuration parameters specific to the rule type |
| `conditions` | map (JSONB) | Conditions that must be met for the rule to apply |
| `priority` | integer | Execution order (higher priority runs first) |
| `active` | boolean | Whether the rule is currently active |
| `start_date` | utc_datetime | When the rule becomes active |
| `end_date` | utc_datetime | When the rule expires |
| `inserted_at` | utc_datetime | Record creation timestamp |
| `updated_at` | utc_datetime | Last update timestamp |



