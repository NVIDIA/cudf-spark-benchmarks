
SELECT 
    c.c_customer_id,
    ca.ca_city,
    sd.d_year,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
WHERE 
    sd.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city, sd.d_year
ORDER BY 
    total_sales DESC
LIMIT 10;
