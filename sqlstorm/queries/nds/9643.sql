
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_stats cs
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_qty,
    rc.total_spent,
    r.r_reason_desc AS most_common_return_reason,
    CASE 
        WHEN rc.total_spent >= 1000 THEN 'Platinum'
        WHEN rc.total_spent >= 500 THEN 'Gold'
        ELSE 'Silver' 
    END AS customer_tier
FROM 
    ranked_customers rc
LEFT JOIN 
    store_returns sr ON rc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    rc.spending_rank <= 10
ORDER BY 
    rc.cd_gender, rc.total_spent DESC;
