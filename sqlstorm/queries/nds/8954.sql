
WITH sales_summary AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, s.s_store_name
),
top_stores AS (
    SELECT 
        d_year,
        s_store_name,
        total_sales,
        num_transactions,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d_year,
    s_store_name,
    total_sales,
    num_transactions,
    avg_sales_price
FROM 
    top_stores
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, total_sales DESC;
