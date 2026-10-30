
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.ss_ticket_number, 
    s.ss_quantity, 
    s.ss_sales_price, 
    d.d_date
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022 
    AND s.ss_quantity > 1
ORDER BY 
    d.d_date, c.c_last_name;
