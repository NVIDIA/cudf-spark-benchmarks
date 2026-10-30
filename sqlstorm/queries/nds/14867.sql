
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    cd.cd_gender = 'M'
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_net_profit DESC
LIMIT 100;
