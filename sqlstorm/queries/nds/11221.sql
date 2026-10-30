
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
