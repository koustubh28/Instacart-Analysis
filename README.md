# 🛒 Instacart Market Basket Analysis using Snowflake

## 📌 Project Overview

This project analyzes customer purchasing behavior using the **Instacart Online Grocery Shopping Dataset**. The objective was to build an end-to-end analytical workflow in **Snowflake** and uncover actionable business insights through advanced SQL techniques.

Instead of treating SQL as a collection of queries, this project follows a structured analytics engineering approach:

**Raw CSV Files → Snowflake Stage → Data Warehouse → Business Analytics → Visualizations**

---

# 🎯 Business Objectives

This project answers the following business questions:

* Which departments generate the highest customer engagement?
* Which products have the highest reorder rates?
* How large is the average customer basket?
* Which products are frequently purchased together?
* Which product combinations have the strongest purchasing relationship?
* How can these insights improve recommendation systems and cross-selling strategies?

---

# 🏗️ Data Architecture

```
CSV Files
      │
      ▼
Snowflake Internal Stage
      │
      ▼
RAW Tables
      │
      ▼
Dimension Views
      │
      ▼
Fact View
      │
      ▼
Business Analysis
      │
      ▼
Dashboards & Insights
```

---

# 📂 Dataset

**Source:** Instacart Online Grocery Shopping Dataset

Tables used:

* Orders
* Order Products Prior
* Products
* Departments
* Aisles

---

# ⭐ Data Modeling

## Fact View

### fact_order_products

Contains one row per product purchased in an order.

Measures include:

* Product purchased
* Reordered flag
* Cart position
* Customer order history

---

## Dimension View

### dim_products

Includes:

* Product Name
* Department
* Aisle

---

# 🛠️ Technologies Used

* Snowflake
* SnowSQL
* SQL
* Excel

---

# 💡 SQL Concepts Demonstrated

* INNER JOIN
* Self JOIN
* Common Table Expressions (CTEs)
* Window Functions

  * RANK()
  * NTILE()
  * LAG()
* Aggregations
* HAVING
* CASE
* Views
* Fact & Dimension Modeling

---

# 📊 Analyses Performed

## 1. Department Performance Analysis

Identified departments contributing the highest order volume.

**Business Value**

* Understand customer demand across departments.

---

## 2. Department Reorder Analysis

Calculated reorder rate for each department.

**Business Value**

* Identify departments driving customer loyalty.

---

## 3. Customer Ordering Behaviour

Analyzed ordering frequency and customer activity.

Used:

* CTE
* NTILE()

---

## 4. Basket Size Analysis

Calculated:

* Average basket size
* Minimum basket size
* Maximum basket size

**Business Value**

* Understand shopping habits and basket composition.

---

## 5. Product Affinity Analysis

Generated product pairs using **Self Joins**.

Calculated:

* Product Support
* Pair Support
* Lift

**Business Value**

Identify products that customers purchase together more frequently than expected by chance.

---

# 🔍 Key Business Insights

* Fresh produce departments showed the highest reorder rates, indicating strong customer loyalty.
* Customer purchasing behavior is highly concentrated in a relatively small group of repeat shoppers.
* Frequently purchased product pairs are not always the strongest product associations.
* Lift analysis revealed hidden relationships between products that can be used for recommendation systems and bundled promotions.
* Basket analysis provides opportunities to improve cross-selling strategies.

---

# 🚀 Future Enhancements

* Product recommendation engine
* Customer Lifetime Value (CLV)
* Cohort Retention Analysis
* Dashboard in Power BI / Tableau
* dbt implementation
* Airflow orchestration

---

# 📚 Key Learnings

This project strengthened my understanding of:

* Building analytical data models in Snowflake
* Loading large datasets using Internal Stages, PUT, and COPY INTO
* Designing Fact and Dimension models
* Applying advanced SQL for business analytics
* Translating SQL outputs into business insights

---

# 📌 Author

**Koustubh Muktibodh**

If you found this project useful or have suggestions for improvement, feel free to connect or open an issue.
