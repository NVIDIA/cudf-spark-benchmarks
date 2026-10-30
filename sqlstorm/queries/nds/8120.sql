
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        unique_items,
        avg_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.unique_items,
    tc.avg_profit,
    cad.ca_city,
    cad.ca_state
FROM 
    top_customers tc
JOIN 
    customer_address cad ON tc.c_customer_id = cad.ca_address_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
