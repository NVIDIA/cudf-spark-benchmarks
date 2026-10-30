
WITH SalesSummary AS (
    SELECT 
        s.s_store_id,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        s.s_store_id
),
TopStores AS (
    SELECT 
        s.s_store_id AS store_id,
        total_sales,
        total_revenue,
        avg_sales_price,
        total_quantity_sold,
        unique_customers,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SalesSummary s
)
SELECT 
    ts.store_id,
    ts.total_sales,
    ts.total_revenue,
    ts.avg_sales_price,
    ts.total_quantity_sold,
    ts.unique_customers,
    CURRENT_DATE - INTERVAL '1 month' AS report_month
FROM 
    TopStores ts
WHERE 
    ts.revenue_rank <= 10
ORDER BY 
    ts.total_revenue DESC;
