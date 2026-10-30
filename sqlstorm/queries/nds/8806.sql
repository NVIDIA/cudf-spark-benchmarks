
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_net_paid) AS total_sales,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year = 2023 
    AND (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    d.d_month_seq, 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_sales DESC, 
    total_quantity_sold DESC
LIMIT 10;
