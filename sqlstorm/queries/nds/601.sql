
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, sales_count
    FROM CustomerSales
    WHERE total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        hd.hd_income_band_sk,
        cd.cd_gender,
        COUNT(DISTINCT s.ss_store_sk) AS store_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_demo_sk, hd.hd_income_band_sk, cd.cd_gender
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(d.store_count, 0) AS store_count,
    d.hd_income_band_sk
FROM HighValueCustomers c
FULL OUTER JOIN CustomerDemographics d ON c.c_customer_sk = d.cd_demo_sk
WHERE (c.total_sales IS NOT NULL OR d.store_count > 0)
ORDER BY total_sales DESC, store_count DESC;
