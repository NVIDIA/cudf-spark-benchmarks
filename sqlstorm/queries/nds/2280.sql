
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_online_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id
),
SalesAggregate AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(total_online_sales, 0) AS total_online_sales,
        COALESCE(total_catalog_sales, 0) AS total_catalog_sales,
        online_order_count,
        catalog_order_count,
        store_order_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(total_online_sales, 0) + COALESCE(total_catalog_sales, 0) DESC) AS sales_rank
    FROM
        CustomerSales c
),
IncomeLevel AS (
    SELECT
        cd.cd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('Income: $', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band
    FROM
        household_demographics hd
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    sa.c_customer_id,
    sa.total_online_sales,
    sa.total_catalog_sales,
    il.income_band,
    sa.online_order_count,
    sa.catalog_order_count,
    sa.store_order_count,
    sa.sales_rank
FROM
    SalesAggregate sa
    LEFT JOIN IncomeLevel il ON sa.c_customer_sk = il.cd_demo_sk
WHERE
    (sa.total_online_sales > 1000 OR sa.total_catalog_sales > 1000)
    AND (sa.total_online_sales IS NOT NULL OR sa.total_catalog_sales IS NOT NULL)
ORDER BY
    sa.sales_rank;
