
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_moy IN (11, 12) 
    GROUP BY 
        c.c_customer_id
), top_customers AS (
    SELECT 
        *
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_orders,
    tc.total_net_profit,
    tc.total_quantity_sold,
    tc.avg_sales_price
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
ORDER BY 
    tc.total_net_profit DESC;
