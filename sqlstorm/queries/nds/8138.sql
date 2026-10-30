
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    MIN(ss.ss_sold_date_sk) AS first_sale_date,
    MAX(ss.ss_sold_date_sk) AS last_sale_date
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
    AND c.c_birth_year BETWEEN 1980 AND 2000
    AND ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;
