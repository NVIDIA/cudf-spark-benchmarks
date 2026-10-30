SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2458849 AND 2458859 
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 100;