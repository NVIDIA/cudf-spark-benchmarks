
WITH RevenueData AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_revenue,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS average_transaction_value,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        s.s_store_id, s.s_store_name, d.d_year
),
RevenueRank AS (
    SELECT 
        s_store_id,
        s_store_name,
        d_year,
        total_revenue,
        total_transactions,
        average_transaction_value,
        unique_customers,
        RANK() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueData
)
SELECT 
    r.s_store_name,
    r.d_year,
    r.total_revenue,
    r.total_transactions,
    r.average_transaction_value,
    r.unique_customers,
    r.revenue_rank
FROM 
    RevenueRank r
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.d_year, r.revenue_rank;
