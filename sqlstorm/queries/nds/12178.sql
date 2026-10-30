
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_sales_price) AS total_sales_amount
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND ss.ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    c.c_customer_id, 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
