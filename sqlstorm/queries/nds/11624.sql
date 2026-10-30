
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(d.d_year) AS average_year,
    MAX(i.i_current_price) AS max_item_price
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
