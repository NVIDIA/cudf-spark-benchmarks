
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_net_profit) AS average_profit,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date,
    ca.ca_city,
    ca.ca_state,
    d.d_year
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_year
HAVING 
    SUM(ss.ss_sales_price) > 5000
ORDER BY 
    total_sales DESC
LIMIT 10;
