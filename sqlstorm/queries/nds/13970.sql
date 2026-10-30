
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    COUNT(cs.c_customer_id) AS customer_count,
    AVG(cs.total_spent) AS avg_spent
FROM 
    customer_summary cs
GROUP BY 
    cs.cd_gender, cs.cd_marital_status
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
