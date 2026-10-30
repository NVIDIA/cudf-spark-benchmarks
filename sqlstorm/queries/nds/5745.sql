
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
),
SalesAnalysis AS (
    SELECT
        ca.ca_city AS city,
        ca.ca_state AS state,
        SUM(cs.total_web_sales) AS total_web_sales_by_city,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_city,
        SUM(cs.total_store_sales) AS total_store_sales_by_city,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM
        CustomerSales cs
    JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_city,
        ca.ca_state
)
SELECT
    city,
    state,
    total_web_sales_by_city,
    total_catalog_sales_by_city,
    total_store_sales_by_city,
    customer_count,
    RANK() OVER (ORDER BY total_web_sales_by_city DESC) AS web_sales_rank,
    RANK() OVER (ORDER BY total_catalog_sales_by_city DESC) AS catalog_sales_rank,
    RANK() OVER (ORDER BY total_store_sales_by_city DESC) AS store_sales_rank
FROM
    SalesAnalysis
WHERE
    customer_count > 0
ORDER BY
    total_web_sales_by_city DESC, total_catalog_sales_by_city DESC, total_store_sales_by_city DESC;
