
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        CASE 
            WHEN SUM(ws.ws_sales_price) > SUM(cs.cs_sales_price) THEN 'Web'
            WHEN SUM(ws.ws_sales_price) < SUM(cs.cs_sales_price) THEN 'Catalog'
            ELSE 'Equal'
        END AS preferred_sales_channel
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_web_orders,
    cs.total_catalog_orders,
    cs.preferred_sales_channel,
    d.cd_gender,
    d.cd_marital_status,
    d.ib_lower_bound,
    d.ib_upper_bound,
    COALESCE(cs.total_web_sales, 0) - COALESCE(cs.total_catalog_sales, 0) AS sales_difference
FROM CustomerSales cs
FULL OUTER JOIN Demographics d ON cs.c_current_cdemo_sk = d.cd_demo_sk
WHERE (cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000)
  AND (d.cd_gender = 'F' AND d.cd_marital_status IS NOT NULL)
ORDER BY sales_difference DESC
LIMIT 100 OFFSET 0;
