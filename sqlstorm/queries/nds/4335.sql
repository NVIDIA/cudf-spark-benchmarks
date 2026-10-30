WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) AS total_sales,
        CASE 
            WHEN cs.total_web_sales > cs.total_catalog_sales THEN 'Web'
            WHEN cs.total_catalog_sales > cs.total_web_sales THEN 'Catalog'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        customer_sales cs
),
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.c_customer_id,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_sales,
    r.preferred_channel,
    d.d_date AS report_date
FROM 
    ranked_sales r
CROSS JOIN date_dim d 
WHERE 
    d.d_date = cast('2002-10-01' as date)
    AND r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;