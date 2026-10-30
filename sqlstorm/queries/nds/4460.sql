
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN customer c ON ss.c_customer_id = c.c_customer_id
    WHERE ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
    ORDER BY ss.total_sales DESC
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    ROW_NUMBER() OVER (ORDER BY tc.total_sales DESC) AS rank,
    CASE 
        WHEN August_Sales > 0 THEN 'Loyal Customer'
        ELSE NULL
    END AS customer_category
FROM 
    top_customers tc
JOIN (
    SELECT 
        c.c_customer_id,
        SUM(CASE 
            WHEN d.d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_date = '2023-08-01') 
            THEN ws.ws_net_paid 
            ELSE 0 
        END) AS August_Sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
) AS aug_sales ON tc.c_customer_id = aug_sales.c_customer_id
WHERE 
    tc.total_sales IS NOT NULL
ORDER BY tc.total_sales DESC
LIMIT 100;
