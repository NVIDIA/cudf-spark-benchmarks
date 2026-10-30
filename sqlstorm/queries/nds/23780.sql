
WITH  income_ranges AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib_upper_bound IS NULL THEN 'Unlimited'
            ELSE CONCAT(ib_lower_bound, '-', ib_upper_bound)
        END AS income_range
    FROM income_band
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate <= 1000 AND cd.cd_purchase_estimate > 500 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category,
        ib.income_range
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_ranges ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_totals AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.dependents,
        ci.purchase_estimate,
        ci.purchase_category,
        ci.income_range,
        COALESCE(st.total_spent, 0) AS total_spent,
        st.order_count
    FROM customer_info ci
    LEFT JOIN sales_totals st ON ci.c_customer_sk = st.ws_bill_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.dependents,
    fr.purchase_estimate,
    fr.purchase_category,
    fr.income_range,
    fr.total_spent,
    fr.order_count,
    RANK() OVER (PARTITION BY fr.purchase_category ORDER BY fr.total_spent DESC) AS spend_rank
FROM final_report fr
WHERE 
    (fr.total_spent > 0 OR fr.purchase_category = 'Low')
    AND fr.cd_gender IS NOT NULL
ORDER BY fr.purchase_category, fr.total_spent DESC
LIMIT 10;
