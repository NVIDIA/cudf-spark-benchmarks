
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        SUM(cs.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.ss_ticket_number) AS total_transactions,
        AVG(cs.ss_sales_price) AS avg_sales_price
    FROM customer c
    JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY c.c_customer_sk
),
demographic_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.total_sales) AS customer_count,
        AVG(cs.total_sales) AS avg_sales_per_customer
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sales_by_income_band AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(cs.c_customer_sk) AS total_customers,
        SUM(cs.total_sales) AS total_sales_by_income_band,
        AVG(cs.avg_sales_price) AS avg_sales_price_by_income_band
    FROM income_band ib
    JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    ib.ib_income_band_sk,
    SUM(da.customer_count) AS total_customers,
    SUM(da.avg_sales_per_customer) AS avg_sales_per_customer_by_demographics,
    SUM(sb.total_sales_by_income_band) AS total_sales_by_income_band
FROM demographic_analysis da
JOIN sales_by_income_band sb ON da.customer_count > 0
JOIN income_band ib ON sb.ib_income_band_sk = ib.ib_income_band_sk
GROUP BY da.cd_gender, da.cd_marital_status, ib.ib_income_band_sk
ORDER BY da.cd_gender, da.cd_marital_status, ib.ib_income_band_sk;
