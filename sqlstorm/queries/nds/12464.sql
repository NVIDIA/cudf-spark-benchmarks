
SELECT 
    cs.cs_item_sk, 
    SUM(cs.cs_quantity) AS total_quantity_sold, 
    SUM(cs.cs_sales_price) AS total_sales_amount, 
    AVG(cs.cs_sales_price) AS avg_sales_price
FROM 
    catalog_sales cs
JOIN 
    date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
JOIN 
    customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    cs.cs_item_sk
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
