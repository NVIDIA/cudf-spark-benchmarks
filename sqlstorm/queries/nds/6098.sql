
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        s.s_store_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, s.s_store_id
),
top_stores AS (
    SELECT 
        sales_year,
        s_store_id,
        total_sales,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    t.sales_year,
    t.s_store_id,
    t.total_sales,
    t.sales_rank,
    c.cc_name AS call_center_name
FROM top_stores t
JOIN call_center c ON t.s_store_id = c.cc_call_center_id
WHERE t.sales_rank <= 5
ORDER BY t.sales_year, t.sales_rank;
