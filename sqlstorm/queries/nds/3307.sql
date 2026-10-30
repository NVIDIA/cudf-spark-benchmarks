
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent
    FROM 
        customer_summary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    CASE 
        WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
        ELSE cd.cd_marital_status 
    END AS marital_status,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY hvc.total_spent DESC) as rank_by_gender
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer c ON hvc.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY 
    hvc.total_spent DESC, hvc.c_last_name ASC;
