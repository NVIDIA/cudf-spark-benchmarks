
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cd.cd_dep_count > 2
GROUP BY 
    c.c_customer_id, cd.cd_gender
ORDER BY 
    total_sales DESC
LIMIT 100;
