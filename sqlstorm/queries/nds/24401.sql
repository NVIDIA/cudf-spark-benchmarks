
WITH  sales_cte AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price > 100 THEN 'Expensive'
            WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cheap'
        END AS price_category
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
total_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_spent,
        COUNT(s.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        sales_cte s ON c.c_customer_sk = s.ws_item_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
    GROUP BY 
        c.c_customer_id
),
sales_analysis AS (
    SELECT 
        cs.c_customer_id,
        ts.total_spent,
        ts.order_count,
        CASE 
            WHEN ts.total_spent IS NULL THEN 'No Purchases'
            WHEN ts.total_spent > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer cs
    LEFT JOIN 
        total_sales ts ON cs.c_customer_id = ts.c_customer_id
)
SELECT 
    s.customer_value,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent,
    MAX(order_count) AS max_orders,
    MIN(order_count) AS min_orders
FROM 
    sales_analysis s
GROUP BY 
    s.customer_value
ORDER BY 
    CASE 
        WHEN s.customer_value = 'High Value' THEN 1
        WHEN s.customer_value = 'Low Value' THEN 2
        ELSE 3
    END;
