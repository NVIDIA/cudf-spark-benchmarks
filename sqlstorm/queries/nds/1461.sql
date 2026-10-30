WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS total_spend,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
    FROM 
        customer_data
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.total_spend,
    COALESCE(tc.online_orders, 0) AS online_orders,
    CASE 
        WHEN tc.total_spend >= 1000 THEN 'Platinum'
        WHEN tc.total_spend >= 500 THEN 'Gold'
        WHEN tc.total_spend >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier
FROM 
    top_customers tc
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    tc.total_spend DESC;