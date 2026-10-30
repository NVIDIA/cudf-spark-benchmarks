
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (
        SELECT MIN(ws_sub.ws_sold_date_sk)
        FROM web_sales ws_sub
        WHERE ws_sub.ws_net_paid > 100
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_sk) AS active_customers,
        AVG(cs.total_sales) AS avg_sales
    FROM customer_demographics cd
    LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
income_bracket AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
final_report AS (
    SELECT 
        da.cd_gender,
        da.cd_marital_status,
        SUM(da.active_customers) AS total_customers,
        SUM(da.avg_sales) AS total_sales,
        ib.household_count
    FROM demographics_analysis da
    JOIN income_bracket ib ON da.active_customers > 0
    GROUP BY da.cd_gender, da.cd_marital_status, ib.household_count
)

SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_customers,
    fr.total_sales,
    COALESCE(NULLIF(fr.household_count, 0), 1) AS effective_households,
    fr.total_sales / NULLIF(fr.total_customers, 0) AS avg_sales_per_customer,
    ROW_NUMBER() OVER (PARTITION BY fr.cd_gender ORDER BY fr.total_sales DESC) AS sales_rank
FROM final_report fr
WHERE fr.total_sales IS NOT NULL
ORDER BY fr.total_sales DESC, fr.total_customers DESC;
