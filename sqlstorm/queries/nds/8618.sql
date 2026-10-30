
WITH sales_summary AS (
    SELECT 
        s.s_store_name AS store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        s.s_store_name, d.d_year, d.d_month_seq
),
monthly_growth AS (
    SELECT 
        store_name,
        d_year,
        d_month_seq,
        total_sales,
        transaction_count,
        LAG(total_sales) OVER (PARTITION BY store_name ORDER BY d_year, d_month_seq) AS previous_month_sales
    FROM 
        sales_summary
),
growth_rate AS (
    SELECT 
        store_name,
        d_year,
        d_month_seq,
        total_sales,
        transaction_count,
        (total_sales - COALESCE(previous_month_sales, 0)) / NULLIF(previous_month_sales, 0) * 100 AS sales_growth_percentage
    FROM 
        monthly_growth
)
SELECT 
    store_name,
    d_year,
    d_month_seq,
    total_sales,
    transaction_count,
    sales_growth_percentage
FROM 
    growth_rate
WHERE 
    sales_growth_percentage IS NOT NULL AND 
    sales_growth_percentage > 10
ORDER BY 
    store_name, d_year, d_month_seq;
