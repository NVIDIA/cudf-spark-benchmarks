
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_value,
        cs.gender_rank,
        ROW_NUMBER() OVER (PARTITION BY cs.gender_rank ORDER BY cs.total_orders DESC) AS customer_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_orders > 5
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    tc.avg_order_value,
    CASE 
        WHEN tc.gender_rank IS NULL THEN 'Unranked' 
        ELSE CAST(tc.gender_rank AS STRING)
    END AS gender_rank,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.customer_rank <= 10 OR tc.total_spent > 500
ORDER BY 
    tc.total_spent DESC;
