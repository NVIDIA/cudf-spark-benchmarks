
WITH customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_amount_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
top_customers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_amount_spent DESC) AS rank_in_band
    FROM
        customer_summary
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_orders,
    tc.total_amount_spent
FROM 
    top_customers tc
LEFT JOIN income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    tc.rank_in_band <= 10
ORDER BY 
    tc.hd_income_band_sk, tc.total_amount_spent DESC
