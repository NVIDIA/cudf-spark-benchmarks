
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (3, 4)
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cp.total_spent,
    COUNT(DISTINCT rs.total_orders) AS total_items_ordered,
    rs.total_quantity_sold,
    rs.total_sales_value
FROM 
    customer_purchases cp
JOIN 
    customer c ON cp.c_customer_sk = c.c_customer_sk
JOIN 
    ranked_sales rs ON rs.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk BETWEEN 20230101 AND 20231231
        GROUP BY 
            ws_item_sk
        ORDER BY 
            SUM(ws_sales_price) DESC
        LIMIT 10
    )
GROUP BY 
    c.c_customer_id, cp.total_spent, rs.total_quantity_sold, rs.total_sales_value
ORDER BY 
    cp.total_spent DESC
LIMIT 100;
