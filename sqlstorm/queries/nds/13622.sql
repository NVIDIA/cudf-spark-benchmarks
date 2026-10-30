
SELECT 
    C.c_customer_id,
    C.c_first_name,
    C.c_last_name,
    SUM(WS.ws_sales_price) AS total_sales,
    D.d_year
FROM 
    customer C
JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
JOIN 
    date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
WHERE 
    D.d_year BETWEEN 2020 AND 2023
GROUP BY 
    C.c_customer_id, C.c_first_name, C.c_last_name, D.d_year
ORDER BY 
    total_sales DESC
LIMIT 10;
