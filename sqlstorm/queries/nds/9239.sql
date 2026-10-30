
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS max_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        max_profit,
        avg_net_paid,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
        d_year
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.max_profit,
    tc.avg_net_paid,
    tc.d_year
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.d_year, tc.total_sales DESC;
