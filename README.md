# 🛒 Retail Dataset Documentation

## 📊 Dataset Overview

|Dataset|Rows|Columns|Grain|
|:---|:---|:---|:---|
|**customer_transactions**|60,000|39|Customer-Month-Store|
|**customer_demographics**|10,000|8|Customer|
|**store_info**|30|10|Store|

---

## ⭐ Star Schema Design

This dataset implements a Star Schema for optimized analytical performance:

```
           Dimension                Fact Table               Dimension
              ┌─────────────────────────────────────────────────┐
              │                                                 │
   customer_demographics                                   store_info
   ┌──────────────────┐          customer_id    store_id  ┌──────────────┐
   │ 10,000 customers │  ────────────┐    ┌──────────────│  30 stores   │
   │                  │              │    │              │              │
   │ • attributes     │              ▼    ▼              │ • attributes │
   │ • attributes     │      customer_transactions       │ • attributes |
   │ • attributes     │      ┌──────────────────┐        │ • attributes |
   │ • attributes     │      │   60,000 rows    │        │ • attributes |
   └──────────────────┘      │                  │        └──────────────┘
                             │ Grain: Customer  │
                             │   × Month        │
                             │   × Store        │
                             │                  │
                             │ Measures:        │
                             │ • Sales amount   │
                             │ • Orders count   │
                             │ • Discounts      │
                             │ • Basket metrics │
                             └──────────────────┘
```

Note: This section focuses on model roles, grain, and measures. For column-level details, see the Schema Quick Reference below.

📊 Model Components

| Component | Table | Role | Grain | Records |
|:---|:---|:---|:---|:---|
| Fact | `customer_transactions` | Measures & metrics | Customer × Month × Store | 60,000 |
| Dimension | `customer_demographics` | Customer attributes | 1 row per customer | 10,000 |
| Dimension | `store_info` | Store attributes | 1 row per store | 30 |

---

## 📋 Schema Quick Reference

### 🧾 customer_transactions (60K rows, 10K customers × 6 months)

<details>
<summary><b>🔑 Identifiers (6)</b></summary>

- `customer_id`, `month`, `store_id`, `store_name`, `city`, `province`

</details>

<details>
<summary><b>👤 Customer Attributes (5)</b></summary>

- `customer_segment` (Regular, Occasional, VIP)
- `is_loyalty_member`, `customer_tenure_months`, `household_size`, `income_bucket` (<50k, 50-100k, >100k)

</details>

<details>
<summary><b>📈 Transaction Metrics (4)</b></summary>

- `orders_count`, `morning_orders`, `midday_orders`, `evening_orders`

</details>

<details>
<summary><b>🛍️ Product & Basket (7)</b></summary>

- `distinct_products`, `unit_prices`, `quantities`, `line_subtotals`
- `basket_size_unique`, `avg_unit_price`, `items_value_sum`

</details>

<details>
<summary><b>💰 Financial Metrics (4)</b></summary>

- `month_subtotal`, `month_discount`, `month_tax`, `month_total`

</details>

<details>
<summary><b>🎯 Behavioral Attributes (6)</b></summary>

- `top_category`, `dominant_payment_method` (Credit/Debit/Cash/Mobile)
- `promotion_applied`, `season`, `has_back_to_school`, `big_customer`

</details>

<details>
<summary><b>⚠️ Data Quality Flags (7)</b></summary>

- `data_errors`, `dominant_payment_method_error`, `unit_prices_error`
- `store_name_error`, `month_error`, `subtotal_error`, `duplicate_error`

</details>

---

### 👥 customer_demographics (10K rows)

<details>
<summary><b>📋 View Schema (8 columns)</b></summary>

|Field|Description|
|:---|:---|
|`customer_id` 🔑|Unique identifier|
|`customer_segment`|Regular / Occasional / VIP|
|`is_loyalty_member`|Boolean|
|`household_size`|Number of people|
|`income_bucket`|<50k / 50-100k / >100k|
|`customer_tenure_months`|Months since first purchase|
|`age`|Years|
|`gender`|M / F / Other|

</details>

---

### 🏪 store_info (30 rows)

<details>
<summary><b>📋 View Schema (10 columns)</b></summary>

|Field|Description|
|:---|:---|
|`store_id` 🔑|Unique identifier|
|`store_name`, `city`, `province`|Location|
|`lat`, `lon`|Coordinates|
|`store_size_sqft`|Square footage|
|`num_employees`|Staff count|
|`store_type`|Neighborhood / Superstore / Express|
|`avg_daily_customers`|Daily traffic|

</details>

---

## 1. Data Quality Checking & Cleaning

### Findings

First, we removed 1,662 rows from the customer transactions table that were flagged with data errors. Main issues were missing payment method, store‑name whitespace, subtotal mismatches, potential duplicates, negative prices, and future‑month labels.

During validation, order count inconsistencies appeared only when the total orders were zero. For records with a positive order count, the sum of morning, midday, and evening orders matched the total. The zero‑order inconsistencies were concentrated among Occasional customers.

Outliers identified with the IQR method for order count, monthly total, and average unit price affected roughly one percent of records and were not remediated. In this iteration, cleaning was limited to removing rows with data errors; no imputations or other rule‑based fixes were performed.

### What it checks

- Basic cleaning of error‑marked rows in `customer_transactions`.
- Key integrity: PK/FK checks and composite key uniqueness in transactions.
- Core business rules: orders add‑up check and financial total identity.
- Nulls and time‑coverage snapshot across the three tables.
- Quick outlier scan and light profiling of demographics and stores.
