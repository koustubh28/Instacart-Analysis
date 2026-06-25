/* Initialize Database */
USE DATABASE INSTACART_RAW;
/* Activate Schema */
USE SCHEMA PUBLIC;
-------- Build Core Analytical Layer -----------------
/* Creating views first - dim_products */
CREATE
OR REPLACE VIEW dim_products AS
SELECT
    p.product_id,
    p.product_name,
    a.aisle,
    d.department
FROM
    products p
    LEFT JOIN aisles a ON p.aisle_id = a.aisle_id
    LEFT JOIN departments d ON p.department_id = d.department_id;
    /* Creating views second - fact_order_products */
    CREATE
    OR REPLACE VIEW fact_order_products AS
SELECT
    op.order_id,
    o.user_id,
    o.order_number,
    o.order_dow,
    o.order_hour_of_day,
    o.days_since_prior_order,
    op.product_id,
    op.add_to_cart_order,
    op.reordered
FROM
    order_products_prior op
    JOIN orders o ON op.order_id = o.order_id;
-------------- Business Questions -----------------------
    /* Reorder Rate by Department */
SELECT
    d.department,
    COUNT(*) AS total_items,
    SUM(f.reordered) AS reordered_items,
    ROUND(AVG(f.reordered) * 100, 2) AS reorder_rate_pct
FROM
    fact_order_products f
    JOIN dim_products d ON f.product_id = d.product_id
GROUP BY
    d.department
ORDER BY
    reorder_rate_pct DESC;
--------------------------------------------------------------------------
    /* Reorder Rate by Aisles */
SELECT
    d.aisle,
    COUNT(*) AS total_items,
    SUM(f.reordered) AS reordered_items,
    ROUND(AVG(f.reordered) * 100, 2) AS reorder_rate_pct
FROM
    fact_order_products f
    JOIN dim_products d ON f.product_id = d.product_id
GROUP BY
    d.aisle
ORDER BY
    reorder_rate_pct DESC;
-------------------------------------------------------------------------------
    /* Customer Behavior View */
SELECT
    user_id,
    COUNT(*) AS total_items,
    COUNT(DISTINCT order_number) AS total_orders,
    MAX(order_number) AS last_order_number,
    RANK() OVER (
        ORDER BY
            COUNT(*) DESC
    ) AS item_rank
FROM
    fact_order_products
GROUP BY
    user_id
ORDER BY
    total_items DESC;
--------------------------------------------------------------------------------------
    /* 🎯 Analysis 1: Department Performance
    Business Question: 
        Which departments drive the most purchases? */
SELECT
    d.department,
    COUNT(*) AS total_items
FROM
    fact_order_products f
    JOIN dim_products d ON f.product_id = d.product_id
GROUP BY
    d.department
ORDER BY
    total_items DESC;
-----------------------------------------------------------------------------------
    /* 🎯 Analysis 2: Reorder Rate by Department
    Business Question: 
        Which departments create the strongest customer loyalty? */
SELECT
    d.department,
    COUNT(*) AS total_items,
    SUM(f.reordered) AS reordered_items,
    ROUND(AVG(f.reordered) * 100, 2) AS reorder_rate_pct
FROM
    fact_order_products f
    JOIN dim_products d ON f.product_id = d.product_id
GROUP BY
    d.department
HAVING
    COUNT(*) > 1000
ORDER BY
    reorder_rate_pct DESC;
------------------------------------------------------------------------------
    /* 🎯 Analysis 3: Top Products Within Each Department
    Business Question: 
        What are the best-selling products inside each department? */
    ---- Used CTE here ----------------
    WITH product_sales AS(
        SELECT
            d.department,
            d.product_name,
            COUNT(*) AS sales_count
        FROM
            fact_order_products f
            JOIN dim_products d ON f.product_id = d.product_id
        GROUP BY
            d.department,
            d.product_name
    )
    --------- Use Rank ----------------------------
SELECT
    *
FROM
    (
        SELECT
            department,
            product_name,
            sales_count,
            RANK() OVER(
                PARTITION BY department
                ORDER BY
                    sales_count DESC
            ) AS product_rank
        FROM
            product_sales
    )
WHERE
    product_rank <= 5
ORDER BY
    department,
    product_rank;
-------------------------------------------------------------------------
    /* 🎯 Analysis 4: Customer Order Frequency Segmentation
    Business Question: 
        Who are our most active customers? */
    WITH customer_orders AS (
        SELECT
            user_id,
            COUNT(DISTINCT order_id) AS total_orders
        FROM
            fact_order_products
        GROUP BY
            user_id
    )
SELECT
    user_id,
    total_orders,
    NTILE(5) OVER (
        ORDER BY
            total_orders ASC
    ) AS customer_segment
FROM
    customer_orders
ORDER BY
    customer_segment DESC,
    total_orders DESC;
-----------------------------------------------------------------------------------
    /* Segment Interpretation */
    WITH customer_orders AS (
        SELECT
            user_id,
            MAX(order_number) AS total_orders
        FROM
            fact_order_products
        GROUP BY
            user_id
    ),
    bucketed_customers AS(
        SELECT
            user_id,
            total_orders,
            NTILE(5) OVER (
                ORDER BY
                    total_orders
            ) AS customer_segment
        FROM
            customer_orders
    )
SELECT
    user_id,
    total_orders,
    customer_segment,
    CASE
        customer_segment
        WHEN 5 THEN 'Power users'
        WHEN 4 THEN 'Loyal'
        WHEN 3 THEN 'Regular'
        WHEN 2 THEN 'Occasional'
        WHEN 1 THEN 'Low activity'
    END AS segment_meaning
FROM
    bucketed_customers
ORDER BY
    total_orders DESC;
------------- For Clean Graph ------------------------------------------
    WITH customer_orders AS (
        SELECT
            user_id,
            COUNT(DISTINCT order_id) AS total_orders
        FROM
            fact_order_products
        GROUP BY
            user_id
    ),
    segmented_customers AS (
        SELECT
            user_id,
            total_orders,
            NTILE(5) OVER (
                ORDER BY
                    total_orders ASC
            ) AS customer_segment
        FROM
            customer_orders
    )
    -- Pre-aggregating for clean, instant charting
SELECT
    customer_segment,
    COUNT(user_id) AS total_customers,
    SUM(total_orders) AS combined_orders,
    ROUND(AVG(total_orders), 1) AS avg_orders_per_customer
FROM
    segmented_customers
GROUP BY
    customer_segment
ORDER BY
    customer_segment DESC;
-----------------------------------------------------------------------
    /* 🎯 Analysis 5: Basket Size Analysis
    Business Question: 
       How many products are customers buying per order? */
    WITH basket_sizes AS (
        SELECT
            order_id,
            COUNT(*) AS basket_size
        FROM
            fact_order_products
        GROUP BY
            order_id
    )
SELECT
    ROUND(AVG(basket_size), 2) AS avg_basket_size,
    MIN(basket_size) AS min_basket_size,
    MAX(basket_size) AS max_basket_size
FROM
    basket_sizes;
-----------------------------------------------------------------------------------------
    /* 🎯 Analysis 5: Product Affinity Analysis
    Business Question: 
       Which products are most frequently purchased together? */
    ---------------- Make Product Pairs -------------------------------------------
    WITH product_pairs AS(
        SELECT
            a.order_id,
            a.product_id AS product_1,
            b.product_id AS product_2
        FROM
            fact_order_products a
            JOIN fact_order_products b ON a.order_id = b.order_id
            AND a.product_id < b.product_id
    )
SELECT
    product_1,
    product_2,
    COUNT(*) AS pair_count
FROM
    product_pairs
GROUP BY
    product_1,
    product_2
ORDER BY
    pair_count DESC
LIMIT
    50;
-------------------- Add Product Names -----------------------------------------
    WITH product_pairs AS (
        SELECT
            a.order_id,
            a.product_id AS product_1,
            b.product_id AS product_2
        FROM
            fact_order_products a
            JOIN fact_order_products b ON a.order_id = b.order_id
            AND a.product_id < b.product_id
    ),
    pair_counts AS (
        SELECT
            product_1,
            product_2,
            COUNT(*) AS pair_count
        FROM
            product_pairs
        GROUP BY
            product_1,
            product_2
    )
SELECT
    p1.product_name AS product_1_name,
    p2.product_name AS product_2_name,
    pair_count
FROM
    pair_counts pc
    JOIN dim_products p1 ON pc.product_1 = p1.product_id
    JOIN dim_products p2 ON pc.product_2 = p2.product_id
ORDER BY
    pair_count DESC
LIMIT
    25;
-----------------------------------------------------------------------------------------
    /* 🎯 Analysis 6: Association Lift
    Business Question: 
       Are these products bought together MORE often than expected by chance? */
    -----------------------------------------------------------
    /* How often each product appears. */
    CREATE
    OR REPLACE VIEW product_lift AS WITH distinct_items AS (
        SELECT
            DISTINCT order_id,
            product_id
        FROM
            fact_order_products
    ),
    pair_counts AS (
        SELECT
            a.product_id AS product_1,
            b.product_id AS product_2,
            COUNT(*) AS pair_count
        FROM
            distinct_items a
            JOIN distinct_items b ON a.order_id = b.order_id
            AND a.product_id < b.product_id
        GROUP BY
            1,
            2
    ),
    product_counts AS (
        SELECT
            product_id,
            COUNT(*) AS product_orders
        FROM
            distinct_items
        GROUP BY
            1
    ),
    total_orders AS (
        SELECT
            COUNT(DISTINCT order_id) AS total_orders
        FROM
            distinct_items
    )
SELECT
    p1.product_name AS product_1_name,
    p2.product_name AS product_2_name,
    pc.pair_count,
    ROUND(
        pc.pair_count * t.total_orders::FLOAT / (c1.product_orders * c2.product_orders),
        4
    ) AS lift
FROM
    pair_counts pc
    JOIN product_counts c1 ON pc.product_1 = c1.product_id
    JOIN product_counts c2 ON pc.product_2 = c2.product_id
    JOIN total_orders t ON 1 = 1
    JOIN dim_products p1 ON pc.product_1 = p1.product_id
    JOIN dim_products p2 ON pc.product_2 = p2.product_id;
SELECT
    *
FROM
    product_lift
ORDER BY
    lift DESC,
    pair_count DESC
LIMIT
    50;