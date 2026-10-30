
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    cs.cs_order_number, 
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN 
    date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cs.cs_order_number
ORDER BY 
    total_sales DESC
LIMIT 100;
