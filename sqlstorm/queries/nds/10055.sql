
SELECT 
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS total_transactions,
    AVG(ss_ext_sales_price) AS avg_sales_per_transaction,
    EXTRACT(YEAR FROM d_date) AS sales_year,
    EXTRACT(MONTH FROM d_date) AS sales_month
FROM 
    store_sales
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk
WHERE 
    d_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    EXTRACT(YEAR FROM d_date),
    EXTRACT(MONTH FROM d_date)
ORDER BY 
    sales_year, sales_month;
