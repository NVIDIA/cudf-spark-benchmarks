
WITH sales_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk OR d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
top_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_web_sales,
        total_catalog_sales,
        web_order_count,
        catalog_order_count,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_catalog_sales,
    CASE
        WHEN tc.web_order_count > 0 THEN ROUND(tc.total_web_sales / tc.web_order_count, 2)
        ELSE NULL
    END AS avg_web_order_value,
    CASE
        WHEN tc.catalog_order_count > 0 THEN ROUND(tc.total_catalog_sales / tc.catalog_order_count, 2)
        ELSE NULL
    END AS avg_catalog_order_value,
    CASE
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.sales_rank;
