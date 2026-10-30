
SELECT 
    d.d_year, 
    SUM(ss_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ss_ticket_number) AS total_transactions, 
    AVG(ss_sales_price) AS average_sales_price
FROM 
    store_sales
JOIN 
    date_dim d ON ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
