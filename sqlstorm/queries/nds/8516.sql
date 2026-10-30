
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
SalesDistribution AS (
    SELECT 
        cd_gender,
        hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS average_sales,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales
    FROM CustomerSales
    GROUP BY cd_gender, hd_income_band_sk
)
SELECT 
    cd_gender,
    ib_lower_bound,
    ib_upper_bound,
    customer_count,
    average_sales,
    max_sales,
    min_sales
FROM SalesDistribution sd
JOIN income_band ib ON sd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY cd_gender, ib_lower_bound;
