
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_revenue
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_gender
ORDER BY 
    total_revenue DESC
LIMIT 100;
