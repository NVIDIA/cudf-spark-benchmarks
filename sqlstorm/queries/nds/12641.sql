
SELECT 
    c.c_customer_id,
    sum(ss.ss_net_profit) AS total_net_profit,
    avg(cd.cd_purchase_estimate) AS average_purchase_estimate,
    count(distinct ss.ss_ticket_number) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
