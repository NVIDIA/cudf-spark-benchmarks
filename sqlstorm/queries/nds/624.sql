
WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
store_sales_info AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales AS ss
    JOIN 
        date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
final_sales AS (
    SELECT 
        COALESCE(m.d_year, s.d_year) AS sales_year,
        COALESCE(m.d_month_seq, s.d_month_seq) AS sales_month,
        COALESCE(m.total_web_sales, 0) AS web_sales,
        COALESCE(s.total_store_sales, 0) AS store_sales,
        COALESCE(m.total_orders, 0) AS web_orders,
        COALESCE(s.total_store_orders, 0) AS store_orders,
        (COALESCE(m.total_web_sales, 0) + COALESCE(s.total_store_sales, 0)) AS total_sales,
        CASE 
            WHEN (COALESCE(m.total_web_sales, 0) + COALESCE(s.total_store_sales, 0)) > 0 
            THEN (COALESCE(m.total_web_sales, 0) + COALESCE(s.total_store_sales, 0) - COALESCE(m.total_web_sales, 0)) / (COALESCE(m.total_web_sales, 0) + COALESCE(s.total_store_sales, 0)) * 100
            ELSE NULL 
        END AS web_sales_percentage
    FROM 
        monthly_sales AS m
    FULL OUTER JOIN 
        store_sales_info AS s ON m.d_year = s.d_year AND m.d_month_seq = s.d_month_seq
)
SELECT 
    sales_year,
    sales_month,
    web_sales,
    store_sales,
    web_orders,
    store_orders,
    total_sales,
    web_sales_percentage
FROM 
    final_sales
ORDER BY 
    sales_year ASC, sales_month ASC;
