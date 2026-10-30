
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_sales,
        ss.order_count,
        ss.avg_profit,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    tc.avg_profit,
    tc.sales_rank,
    d.d_year
FROM 
    top_customers tc
JOIN 
    (SELECT DISTINCT d.d_year FROM date_dim d WHERE d.d_year BETWEEN 2020 AND 2022) d ON 1 = 1
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    d.d_year, tc.sales_rank;
