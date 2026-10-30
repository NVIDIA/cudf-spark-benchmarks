
SELECT 
    ca_county, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    SUM(ws_net_paid) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN 
    web_sales ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
JOIN 
    date_dim ON date_dim.d_date_sk = ws_sold_date_sk
WHERE 
    date_dim.d_year = 2023
GROUP BY 
    ca_county
ORDER BY 
    total_sales DESC
LIMIT 10;
