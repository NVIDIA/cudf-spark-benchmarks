
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_spent DESC) AS rank
    FROM 
        customer_summary
)
SELECT 
    tc.hd_income_band_sk,
    income.ib_lower_bound,
    income.ib_upper_bound,
    COUNT(tc.c_customer_sk) AS num_top_customers,
    AVG(tc.total_spent) AS avg_spent,
    AVG(tc.total_orders) AS avg_orders
FROM 
    top_customers tc
JOIN 
    income_band income ON tc.hd_income_band_sk = income.ib_income_band_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.hd_income_band_sk, income.ib_lower_bound, income.ib_upper_bound
ORDER BY 
    income.ib_lower_bound;
