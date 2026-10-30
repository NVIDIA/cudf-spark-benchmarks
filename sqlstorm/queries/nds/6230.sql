
WITH sales_summary AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        COUNT(s.ss_ticket_number) AS total_sales,
        SUM(s.ss_sales_price) AS total_revenue,
        AVG(s.ss_net_profit) AS average_profit,
        SUM(s.ss_quantity) AS total_quantity_sold
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        EXTRACT(MONTH FROM d.d_date)
),
top_months AS (
    SELECT 
        sale_month,
        total_sales,
        total_revenue,
        average_profit,
        total_quantity_sold,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        sales_summary
)
SELECT 
    tm.sale_month,
    tm.total_sales,
    tm.total_revenue,
    tm.average_profit,
    tm.total_quantity_sold,
    CASE 
        WHEN tm.revenue_rank <= 3 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    top_months tm
WHERE 
    tm.revenue_rank <= 5
ORDER BY 
    tm.revenue_rank;
