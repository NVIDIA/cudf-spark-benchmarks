
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' AND 
    cd.cd_gender = 'F' AND 
    ss.ss_sold_date_sk BETWEEN 10000 AND 20000
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
