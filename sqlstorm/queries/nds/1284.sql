
WITH customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
income_distribution AS (
    SELECT
        h.hd_demo_sk,
        COUNT(*) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS total_income
    FROM household_demographics h
    LEFT JOIN web_sales ws ON h.hd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY h.hd_demo_sk
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_summary cs
    LEFT JOIN income_band ib ON cs.c_current_cdemo_sk = ib.ib_income_band_sk
    WHERE cs.total_sales IS NOT NULL
)
SELECT
    cs.c_customer_sk,
    cs.total_sales,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE 
        WHEN cs.total_sales >= 5000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 1000 AND 4999 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ARRAY_AGG(DISTINCT ws.ws_order_number) AS order_numbers
FROM customer_summary cs
LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN high_value_customers hvc ON cs.c_customer_sk = hvc.c_customer_sk
LEFT JOIN income_band ib ON hvc.ib_income_band_sk = ib.ib_income_band_sk
WHERE ws.ws_ship_date_sk IS NOT NULL OR hvc.sales_rank IS NULL
GROUP BY cs.c_customer_sk, cs.total_sales, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT ws.ws_order_number) > 2
ORDER BY cs.total_sales DESC;
