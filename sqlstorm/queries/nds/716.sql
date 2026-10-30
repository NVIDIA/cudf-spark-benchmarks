
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20240101 AND 20241231
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk
    FROM 
        customer_summary cs
    WHERE 
        cs.total_spent > (
            SELECT AVG(total_spent) FROM customer_summary
        )
)
SELECT 
    COALESCE(s.total_quantity_sold, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales_value,
    c.c_customer_sk,
    c.order_count,
    c.total_spent,
    c.avg_order_value
FROM 
    high_value_customers hvc
JOIN 
    customer_summary c ON hvc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    item_sales s ON s.i_item_sk IN (
        SELECT rs.ws_item_sk 
        FROM ranked_sales rs 
        WHERE rs.price_rank <= 5
    )
WHERE 
    c.order_count > 0
ORDER BY 
    c.total_spent DESC;
