
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    COUNT(s.ss_ticket_number) AS total_sales,
    SUM(s.ss_sales_price) AS total_sales_amount
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, 
    ca.ca_city, 
    cd.cd_gender
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
