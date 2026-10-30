
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_sales_price) AS total_sales_amount
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_quantity_sold DESC
LIMIT 100;
