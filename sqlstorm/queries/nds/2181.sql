
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
income_bounds AS (
    SELECT 
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_range
    FROM 
        income_band ib
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(ib.income_range, 'Not Specified') AS income_range,
    cs.order_count,
    cs.total_spent,
    cs.avg_profit_per_order,
    cs.gender_rank
FROM 
    customer_stats cs
LEFT JOIN 
    household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_bounds ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    (cs.total_spent > 500 OR cs.order_count > 10) 
    AND (cs.cd_gender = 'F' OR cs.cd_marital_status = 'S')
ORDER BY 
    cs.total_spent DESC;
