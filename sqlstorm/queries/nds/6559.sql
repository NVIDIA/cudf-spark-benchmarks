
WITH sales_summary AS (
    SELECT 
        d.d_year,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        store s ON ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, s.s_store_name
),
best_store AS (
    SELECT 
        d_year,
        s_store_name,
        total_sales,
        total_quantity,
        total_transactions,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_quantity DESC) AS quantity_rank
    FROM 
        sales_summary
)
SELECT 
    b.d_year,
    b.s_store_name,
    b.total_sales,
    b.total_quantity,
    b.total_transactions,
    CASE 
        WHEN b.sales_rank = 1 THEN 'Top Sales Store'
        ELSE 'Other Store'
    END AS sales_category,
    CASE 
        WHEN b.quantity_rank = 1 THEN 'Top Quantity Store'
        ELSE 'Other Store'
    END AS quantity_category
FROM 
    best_store b
ORDER BY 
    b.d_year, b.total_sales DESC;
