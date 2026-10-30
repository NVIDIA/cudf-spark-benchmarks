
WITH seasonal_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
item_info AS (
    SELECT
        i_item_sk,
        i_product_name,
        COALESCE(i_current_price, 0) AS current_price,
        COALESCE(i_wholesale_cost, 0) AS wholesale_cost,
        CASE 
            WHEN i_current_price > 0 AND i_wholesale_cost > 0 
            THEN (i_current_price - i_wholesale_cost) / i_current_price 
            ELSE NULL 
        END AS profit_margin
    FROM item
),
customer_purchases AS (
    SELECT
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_order_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
customer_status AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' AND c.total_spent > 10000 THEN 'High Value Male'
            WHEN cd.cd_gender = 'F' AND c.total_spent > 10000 THEN 'High Value Female'
            WHEN c.order_count > 5 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS customer_type
    FROM customer_purchases c
    JOIN customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cs.customer_type,
    COUNT(DISTINCT cs.cd_demo_sk) AS customer_count,
    SUM(ss.total_sales) AS total_sales_by_type,
    AVG(i.current_price) AS avg_current_price,
    AVG(COALESCE(i.wholesale_cost, 0)) AS avg_wholesale_cost,
    SUM(i.profit_margin) / COUNT(i.i_item_sk) AS avg_profit_margin
FROM customer_status cs
LEFT JOIN seasonal_sales ss ON cs.cd_demo_sk = ss.ws_item_sk
LEFT JOIN item_info i ON ss.ws_item_sk = i.i_item_sk
GROUP BY cs.customer_type
HAVING 
    SUM(ss.total_sales) IS NOT NULL 
    OR COUNT(DISTINCT cs.cd_demo_sk) > 0
ORDER BY customer_count DESC, total_sales_by_type DESC;
