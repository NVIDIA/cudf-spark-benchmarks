
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        MAX(ws.ws_sold_date_sk) AS last_web_purchase_date,
        COALESCE(MAX(cs.cs_sold_date_sk), 0) AS last_catalog_purchase_date
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
SalesRanking AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM
        CustomerSales
)
SELECT
    sr.c_customer_sk,
    sr.c_first_name,
    sr.c_last_name,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.web_order_count,
    sr.catalog_order_count,
    CASE
        WHEN sr.total_web_sales IS NULL AND sr.total_catalog_sales IS NULL THEN 'No Sales'
        WHEN sr.total_web_sales IS NULL THEN 'Catalog Only'
        WHEN sr.total_catalog_sales IS NULL THEN 'Web Only'
        ELSE 'Both'
    END AS sales_channel,
    dd.d_date AS last_purchase_date,
    CASE
        WHEN dd.d_date IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM
    SalesRanking sr
LEFT JOIN
    date_dim dd ON dd.d_date_sk = (CASE WHEN sr.last_web_purchase_date > sr.last_catalog_purchase_date THEN sr.last_web_purchase_date ELSE sr.last_catalog_purchase_date END)
WHERE
    sr.sales_rank <= 100
ORDER BY
    sr.sales_rank;
