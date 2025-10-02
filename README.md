# 🛒 Retail Dataset Documentation

## 📊 Dataset Overview

|Dataset|Rows|Columns|Grain|
|:---|:---|:---|:---|
|**customer_transactions**|60,000|39|Customer-Month-Store|
|**customer_demographics**|10,000|8|Customer|
|**store_info**|30|10|Store|

---

## 🔗 Entity Relationships

```
customer_demographics → customer_transactions ← store_info
    (customer_id)           ↑              ↑        (store_id)
                            └──────────────┘
```

**Join Keys:** `customer_id`, `store_id`

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

---

### 🏪 store_info (30 rows)

|Field|Description|
|:---|:---|
|`store_id` 🔑|Unique identifier|
|`store_name`, `city`, `province`|Location|
|`lat`, `lon`|Coordinates|
|`store_size_sqft`|Square footage|
|`num_employees`|Staff count|
|`store_type`|Neighborhood / Superstore / Express|
|`avg_daily_customers`|Daily traffic|

---

## 🎯 Analysis Use Cases

|Use Case|Key Fields|Analysis Type|
|:---|:---|:---|
|**Customer Segmentation**|`customer_segment`, `income_bucket`, `age`, `household_size`|Demographic profiling|
|**Basket Analysis**|`distinct_products`, `quantities`, `basket_size_unique`|Cross-sell opportunities|
|**Store Performance**|`month_total`, `store_type`, `store_size_sqft`|Location optimization|
|**Temporal Patterns**|`month`, `season`, `morning/midday/evening_orders`|Seasonality & timing|
|**Loyalty Impact**|`is_loyalty_member`, `month_total`, `orders_count`|Program effectiveness|
|**Data Quality**|`*_error` flags|Monitoring & cleanup|

---
-- Loyalty member analysis
SELECT cd.is_loyalty_member, AVG(ct.month_total), AVG(ct.orders_count)
FROM customer_transactions ct
JOIN customer_demographics cd ON ct.customer_id = cd.customer_id
GROUP BY cd.is_loyalty_member;
``
