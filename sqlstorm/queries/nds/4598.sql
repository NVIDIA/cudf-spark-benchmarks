
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_id
),
SalesSummary AS (
    SELECT
        cs.c_customer_id,
        cs.total_quantity,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        CASE
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 100 THEN 'Low Sales'
            WHEN cs.total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM
        CustomerSales cs
)
SELECT
    ss.c_customer_id,
    ss.total_quantity,
    ss.total_sales,
    ss.order_count,
    ss.sales_rank,
    ss.sales_category,
    COALESCE(ROUND(AVG(ss.total_sales) OVER (PARTITION BY ss.sales_category), 2), 0) AS avg_sales_in_category
FROM
    SalesSummary ss
WHERE
    ss.order_count > 0
ORDER BY
    ss.sales_rank
LIMIT 100;
