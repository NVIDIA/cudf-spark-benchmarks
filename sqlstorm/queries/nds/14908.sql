
WITH sales_summary AS (
    SELECT 
        ss.ss_sold_date_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        SUM(ss.ss_quantity) AS total_quantity
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ss.ss_sold_date_sk
)
SELECT 
    d.d_date AS sale_date,
    ss.total_sales,
    ss.unique_customers,
    ss.total_quantity
FROM 
    sales_summary ss
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
ORDER BY 
    sale_date;
