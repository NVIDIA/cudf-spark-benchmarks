
SELECT 
    C.c_customer_id,
    CA.ca_city,
    SUM(WS.ws_sales_price) AS total_sales
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
JOIN 
    date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
WHERE 
    D.d_year = 2023
GROUP BY 
    C.c_customer_id, CA.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
