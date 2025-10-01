## Supermarket Dataset Documentation

### Overview

We focus on the following three core datasets:

| File | Description |
|------|-------------|
| **supermarket_6mo_customer_month_10k_customers.csv** | Monthly aggregated transaction data for 10,000 customers over 6 months including purchase behavior, basket composition, payment methods, and promotional activities |
| **supermarket_customer_demographics.csv** | Customer-level demographic attributes such as age, gender, household size, income bracket, loyalty status, and tenure |
| **supermarket_store_info.csv** | Store metadata including location, size, employee count, store type, and average daily customer traffic |

---

### Dataset Schemas

#### 1. supermarket_6mo_customer_month_10k_customers.csv

**Records:** 60,000 rows (10,000 customers × 6 months)  
**Columns:** 39

##### Customer Identifiers

- `customer_id` VARCHAR(100) - Unique customer identifier
- `month` VARCHAR(100) - Transaction month (YYYY-MM format)
- `store_id` VARCHAR(100) - Store identifier
- `store_name` VARCHAR(100) - Store name
- `city` VARCHAR(100) - Store city location
- `province` VARCHAR(100) - Store province/state

##### Customer Attributes

- `customer_segment` VARCHAR(100) - Customer segment classification (Regular, Occasional, VIP)
- `is_loyalty_member` BOOLEAN - Loyalty program membership status
- `customer_tenure_months` INT - Months since first purchase
- `household_size` INT - Number of people in household
- `income_bucket` VARCHAR(100) - Income range category (<50k, 50-100k, >100k)

##### Transaction Metrics

- `orders_count` INT - Number of orders in the month
- `morning_orders` INT - Orders placed during morning hours
- `midday_orders` INT - Orders placed during midday hours
- `evening_orders` INT - Orders placed during evening hours

##### Product & Basket Details

- `distinct_products` VARCHAR(1000) - List of unique products purchased
- `unit_prices` VARCHAR(1000) - Price per unit for each product
- `quantities` VARCHAR(1000) - Quantity purchased for each product
- `line_subtotals` VARCHAR(1000) - Line item subtotals
- `basket_size_unique` INT - Count of unique products
- `avg_unit_price` DECIMAL(10,2) - Average price per product unit
- `items_value_sum` DECIMAL(10,2) - Total value of items

##### Financial Metrics

- `month_subtotal` DECIMAL(10,2) - Monthly subtotal before discounts and tax
- `month_discount` DECIMAL(10,2) - Total discounts applied
- `month_tax` DECIMAL(10,2) - Total tax charged
- `month_total` DECIMAL(10,2) - Final monthly total

##### Behavioral Attributes

- `top_category` VARCHAR(100) - Most frequently purchased product category
- `dominant_payment_method` VARCHAR(100) - Primary payment method used (Credit Card, Debit Card, Cash, Mobile Payment)
- `promotion_applied` BOOLEAN - Whether promotional offers were used
- `season` VARCHAR(100) - Season of transaction (Spring, Summer, Fall, Winter)
- `has_back_to_school` BOOLEAN - Flag for back-to-school shopping activity
- `big_customer` BOOLEAN - High-value customer indicator

##### Data Quality Flags

- `data_errors` VARCHAR(500) - List of detected data errors
- `dominant_payment_method_error` BOOLEAN - Payment method data quality flag
- `unit_prices_error` BOOLEAN - Pricing data quality flag
- `store_name_error` BOOLEAN - Store name data quality flag
- `month_error` BOOLEAN - Month data quality flag
- `subtotal_error` BOOLEAN - Subtotal calculation error flag
- `duplicate_error` BOOLEAN - Duplicate record flag

---

#### 2. supermarket_customer_demographics.csv

**Records:** 10,000 rows (one per unique customer)  
**Columns:** 8

- `customer_id` VARCHAR(100) - Unique customer identifier (primary key)
- `customer_segment` VARCHAR(100) - Customer segment classification
- `is_loyalty_member` BOOLEAN - Loyalty program membership status
- `household_size` INT - Number of people in household
- `income_bucket` VARCHAR(100) - Income range category
- `customer_tenure_months` INT - Months since first purchase
- `age` INT - Customer age in years
- `gender` VARCHAR(50) - Customer gender

---

#### 3. supermarket_store_info.csv

**Records:** 30 rows (one per store location)  
**Columns:** 10

- `store_id` VARCHAR(100) - Unique store identifier (primary key)
- `store_name` VARCHAR(100) - Store name
- `city` VARCHAR(100) - City location
- `province` VARCHAR(100) - Province/state location
- `lat` DECIMAL(9,6) - Latitude coordinate
- `lon` DECIMAL(9,6) - Longitude coordinate
- `store_size_sqft` INT - Store size in square feet
- `num_employees` INT - Number of store employees
- `store_type` VARCHAR(100) - Store format category (Neighborhood, Superstore, Express)
- `avg_daily_customers` INT - Average daily customer traffic

---

### Entity Relationships

```
┌─────────────────────────┐
│  Customer Dimension     │
│  (Demographics)         │
│                         │
│  • customer_id (PK)     │
│  • age                  │
│  • gender               │
│  • household_size       │
│  • income_bucket        │
│  • customer_segment     │
│  • loyalty status       │
│  • tenure               │
└────────┬────────────────┘
         │
         │ customer_id
         │
         ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│  Transaction Fact       │         │  Store Dimension        │
│  (Monthly Aggregates)   │ store_id│  (Location & Ops)       │
│                         ├─────────►                         │
│  • customer_id (FK)     │         │  • store_id (PK)        │
│  • store_id (FK)        │         │  • store_name           │
│  • month                │         │  • location (city/prov) │
│  • orders & timing      │         │  • coordinates (lat/lon)│
│  • basket composition   │         │  • store_size_sqft      │
│  • financial metrics    │         │  • num_employees        │
│  • payment & promotions │         │  • store_type           │
│  • behavioral flags     │         │  • avg_daily_customers  │
└─────────────────────────┘         └─────────────────────────┘
```

These datasets are joined primarily through **customer_id** and **store_id**, enabling both micro-level analysis (e.g., individual customer purchase patterns, basket analysis) and macro-level patterns (e.g., customer segment behavior, store performance comparisons, geographic spending trends).

---

### Key Analysis Dimensions

#### Customer Dimension

- Number of customers by segment, age cohorts, income brackets
- Loyalty member penetration and spending patterns
- Household size distribution and basket size correlation
- Customer tenure and lifetime value analysis

#### Transaction Dimension

- Monthly transaction volume and seasonality
- Time-of-day shopping patterns (morning/midday/evening)
- Basket composition and cross-category purchases
- Payment method preferences and promotional response
- Average order value and discount utilization

#### Store Dimension

- Store performance by location, size, and type
- Geographic market analysis and regional trends
- Store format effectiveness (Neighborhood vs Superstore vs Express)
- Employee productivity and customer traffic patterns
- Store saturation analysis by city and province

---

### Use Cases

1. **Customer Segmentation & Personalization**: Analyze purchasing patterns across demographic segments to develop targeted marketing campaigns and personalized recommendations
2. **Market Basket Analysis**: Identify product associations and cross-selling opportunities through basket composition analysis
3. **Store Operations Optimization**: Evaluate store performance metrics, optimal sizing, and staffing levels based on customer traffic and transaction patterns
4. **Temporal & Seasonal Analysis**: Understand shopping behavior variations by time of day, month, and season to optimize inventory and promotions
5. **Loyalty Program Effectiveness**: Measure impact of loyalty membership on spending, frequency, and basket size
6. **Data Quality Monitoring**: Track and remediate data quality issues using built-in error flags across payment, pricing, and transaction records
