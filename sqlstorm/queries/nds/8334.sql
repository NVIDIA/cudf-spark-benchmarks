
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_month_seq
),
sales_trends AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.d_month_seq,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        LAG(cs.total_sales) OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.d_month_seq) AS prev_month_sales,
        LAG(cs.order_count) OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.d_month_seq) AS prev_month_order_count
    FROM 
        customer_summary cs
),
trends_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.d_month_seq,
        c.total_sales,
        c.order_count,
        c.avg_order_value,
        (c.total_sales - COALESCE(c.prev_month_sales, 0)) AS sales_growth,
        (c.order_count - COALESCE(c.prev_month_order_count, 0)) AS order_growth
    FROM 
        sales_trends c
)
SELECT 
    ta.c_customer_sk,
    ta.c_first_name,
    ta.c_last_name,
    ta.d_month_seq,
    ta.total_sales,
    ta.order_count,
    ta.avg_order_value,
    ta.sales_growth,
    ta.order_growth,
    CASE 
        WHEN ta.sales_growth > 0 AND ta.order_growth > 0 THEN 'Growth'
        WHEN ta.sales_growth < 0 AND ta.order_growth < 0 THEN 'Decline'
        ELSE 'Stable'
    END AS trend_status
FROM 
    trends_analysis ta
ORDER BY 
    ta.total_sales DESC, ta.d_month_seq;
