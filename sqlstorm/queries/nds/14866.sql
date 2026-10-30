
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ss.ss_quantity,
    ss.ss_sales_price,
    ws.ws_sales_price,
    d.d_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_state = 'CA' 
    AND d.d_year = 2023
ORDER BY 
    ss.ss_sales_price DESC
LIMIT 100;
