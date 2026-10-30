
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    dd.d_year, 
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    dd.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
