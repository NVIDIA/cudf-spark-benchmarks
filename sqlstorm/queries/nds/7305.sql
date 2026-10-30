
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS avg_transaction_value,
    MAX(ss.ss_sales_price) AS max_transaction_value,
    MIN(ss.ss_sales_price) AS min_transaction_value,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    d.d_year, 
    d.d_month_seq
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC, 
    c.c_last_name ASC;
