
WITH sales_summary AS (
    SELECT 
        s.ss_store_sk AS store_id,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_paid) AS total_net_revenue
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.ss_store_sk
)
SELECT 
    s.store_id, 
    s.total_quantity_sold, 
    s.total_net_revenue
FROM 
    sales_summary s
ORDER BY 
    s.total_net_revenue DESC
LIMIT 10;
