
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_id
), 
customer_engagement AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ss.ws_sold_date_sk,
    ss.w_warehouse_id,
    ss.total_quantity,
    ss.total_sales,
    ce.total_orders,
    ce.total_spent
FROM 
    sales_summary ss
LEFT JOIN 
    customer_engagement ce ON ce.c_customer_id IN (
        SELECT c.c_customer_id
        FROM customer c 
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-06-30')
    )
ORDER BY 
    ss.ws_sold_date_sk, ss.w_warehouse_id;
