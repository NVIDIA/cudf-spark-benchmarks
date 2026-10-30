
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cm.cd_gender, 
    SUM(ss.ss_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    customer_demographics cm ON c.c_current_cdemo_sk = cm.cd_demo_sk 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    cm.cd_marital_status = 'M' 
GROUP BY 
    c.c_first_name, c.c_last_name, cm.cd_gender 
ORDER BY 
    total_sales DESC 
LIMIT 100;
