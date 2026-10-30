
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count
    FROM
        customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
web_sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
total_sales AS (
    SELECT
        cs.c_customer_id,
        COALESCE(cs.total_store_sales, 0) AS store_sales,
        COALESCE(ws.total_web_sales, 0) AS web_sales,
        (COALESCE(cs.total_store_sales, 0) + COALESCE(ws.total_web_sales, 0)) AS overall_sales
    FROM
        customer_sales cs
    FULL OUTER JOIN web_sales_summary ws ON cs.c_customer_id = ws.c_customer_id
)
SELECT
    t.c_customer_id,
    t.store_sales,
    t.web_sales,
    t.overall_sales,
    CASE
        WHEN t.overall_sales = 0 THEN 'No Purchases'
        WHEN t.overall_sales < 100 THEN 'Low Spend'
        WHEN t.overall_sales BETWEEN 100 AND 500 THEN 'Moderate Spend'
        ELSE 'High Spend'
    END AS spend_category,
    DENSE_RANK() OVER (ORDER BY t.overall_sales DESC) AS sales_rank
FROM
    total_sales t
WHERE
    t.store_sales > 100 OR t.web_sales > 100
ORDER BY
    t.overall_sales DESC
LIMIT 10;
