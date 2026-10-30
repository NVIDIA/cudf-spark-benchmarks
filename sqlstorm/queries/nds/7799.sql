
WITH SalesSummary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_sales_price) AS total_sales_revenue,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        CAST(d.d_date AS DATE) AS sale_date
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND s.s_country = 'USA'
    GROUP BY 
        s.s_store_sk, s.s_store_name, d.d_date
),
RankedSales AS (
    SELECT 
        s.s_store_name AS store_name,
        ss.total_quantity_sold,
        ss.total_sales_revenue,
        ss.unique_customers,
        ss.sale_date,
        RANK() OVER (PARTITION BY ss.sale_date ORDER BY ss.total_sales_revenue DESC) AS revenue_rank
    FROM 
        SalesSummary ss
    JOIN 
        store s ON ss.s_store_sk = s.s_store_sk
)
SELECT 
    store_name,
    total_quantity_sold,
    total_sales_revenue,
    unique_customers,
    sale_date
FROM 
    RankedSales
WHERE 
    revenue_rank <= 5
ORDER BY 
    sale_date, total_sales_revenue DESC;
