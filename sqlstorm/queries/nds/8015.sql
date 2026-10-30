
WITH SalesData AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        s.s_store_name, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesData s
)
SELECT 
    r.s_store_name,
    r.total_quantity_sold,
    r.total_sales,
    r.d_year,
    r.d_month_seq
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 3
ORDER BY 
    r.d_year, r.d_month_seq, r.total_sales DESC;
