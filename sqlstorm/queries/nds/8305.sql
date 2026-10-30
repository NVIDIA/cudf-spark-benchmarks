
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_order_count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_order_count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
),
SalesSummary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(web_order_count) AS avg_web_order_count,
        AVG(catalog_order_count) AS avg_catalog_order_count,
        AVG(store_order_count) AS avg_store_order_count
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    *,
    RANK() OVER (ORDER BY avg_web_sales DESC) AS web_sales_rank,
    RANK() OVER (ORDER BY avg_catalog_sales DESC) AS catalog_sales_rank,
    RANK() OVER (ORDER BY avg_store_sales DESC) AS store_sales_rank
FROM
    SalesSummary
WHERE
    avg_web_sales IS NOT NULL OR avg_catalog_sales IS NOT NULL OR avg_store_sales IS NOT NULL
ORDER BY
    avg_web_sales DESC, avg_catalog_sales DESC, avg_store_sales DESC;
