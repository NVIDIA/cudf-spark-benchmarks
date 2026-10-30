
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
)
SELECT 
    d.d_date AS sale_date, 
    s.total_quantity, 
    s.total_sales, 
    COALESCE(s.total_sales / NULLIF(s.total_quantity, 0), 0) AS avg_sales_price
FROM 
    date_dim d
LEFT JOIN 
    sales_summary s ON d.d_date_sk = s.ws_sold_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
