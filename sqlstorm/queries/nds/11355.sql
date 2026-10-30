
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_net_paid) AS total_sales, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'M' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC 
LIMIT 100;
