
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.unique_ship_dates,
    tc.avg_order_value,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        WHEN tc.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS customer_segment
FROM 
    top_customers AS tc
ORDER BY 
    tc.sales_rank;
