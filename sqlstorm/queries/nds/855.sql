
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY hd.hd_income_band_sk
),
purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid_inc_tax, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
)

SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(isum.customer_count, 0) AS income_band_customer_count,
    ci.total_spent,
    ps.total_web_sales,
    ps.total_catalog_sales,
    ps.total_store_sales
FROM customer_info ci
LEFT JOIN income_summary isum ON ci.c_customer_sk = isum.hd_income_band_sk
LEFT JOIN purchase_summary ps ON ci.c_customer_sk = ps.c_customer_sk
WHERE ci.total_spent > (SELECT AVG(total_spent) FROM customer_info) 
  AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY ci.total_spent DESC
LIMIT 100;
