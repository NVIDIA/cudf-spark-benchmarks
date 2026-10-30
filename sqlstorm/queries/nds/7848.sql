
WITH customer_info AS (
    SELECT 
        c.c_customer_id AS customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), ranked_customers AS (
    SELECT 
        customer_id, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        total_net_profit,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS rank
    FROM 
        customer_info
)
SELECT 
    rc.customer_id, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    rc.cd_education_status, 
    rc.total_net_profit
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, rc.total_net_profit DESC;
