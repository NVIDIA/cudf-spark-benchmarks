
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 20210101 AND 20211231
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_sales DESC
LIMIT 100;
