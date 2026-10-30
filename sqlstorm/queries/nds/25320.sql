
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name, 
    ca.ca_city, 
    ca.ca_state, 
    d.d_date AS purchase_date, 
    COUNT(ss.ss_ticket_number) AS total_purchases, 
    SUM(ss.ss_net_paid) AS total_spent,
    SUBSTRING(ca.ca_street_name, 1, 15) AS street_name_chunk
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND ca.ca_state IN ('CA', 'TX') 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    customer_name, ca.ca_city, ca.ca_state, purchase_date, street_name_chunk
ORDER BY 
    total_spent DESC, total_purchases DESC
LIMIT 100;
