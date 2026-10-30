
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) as web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) as store_order_count,
        COUNT(DISTINCT cs.cs_order_number) as catalog_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
),
ranked_sales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10'
        WHEN r.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS sales_category
FROM 
    ranked_sales r
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM ranked_sales)
ORDER BY 
    r.total_sales DESC
LIMIT 100;
