
WITH  ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank_order
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL AND cd.cd_gender IS NOT NULL
),
customer_incomes AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN hd.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_band,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, hd.hd_income_band_sk
),
top_customers AS (
    SELECT
        rc.c_customer_id,
        ci.income_band,
        ci.total_spent
    FROM 
        ranked_customers rc
    JOIN 
        customer_incomes ci ON rc.c_customer_sk = ci.c_customer_sk
    WHERE 
        rc.rank_order <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    CASE 
        WHEN tc.total_spent > (SELECT AVG(total_spent) FROM customer_incomes) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    top_customers tc
WHERE 
    tc.income_band NOT IN ('Low Income')
ORDER BY 
    tc.total_spent DESC;
