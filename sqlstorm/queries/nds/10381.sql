
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    sa.ws_sales_price, 
    sa.ws_quantity 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    web_sales sa ON c.c_customer_sk = sa.ws_bill_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
AND 
    sa.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023
    ) 
ORDER BY 
    sa.ws_sales_price DESC 
LIMIT 100;
