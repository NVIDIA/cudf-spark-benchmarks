
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_ext_sales_price) AS total_revenue,
    AVG(ss.ss_sales_price) AS average_price
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND ss.ss_sold_date_sk BETWEEN 2459900 AND 2459905
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_revenue DESC;
