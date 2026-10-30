
WITH sales_data AS (
    SELECT 
        cs_item_sk,
        cs_quantity,
        cs_net_profit,
        cs_net_paid_inc_tax,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        d.d_week_seq,
        c.cc_class,
        SUM(cs_quantity) OVER (PARTITION BY cs_item_sk ORDER BY d.d_date_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity
    FROM 
        catalog_sales AS cs
    JOIN 
        date_dim AS d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        call_center AS c ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
profit_analysis AS (
    SELECT 
        d_year,
        d_quarter_seq,
        d_month_seq,
        COUNT(DISTINCT cs_item_sk) AS item_count,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_net_profit) AS avg_profit_per_item,
        SUM(cs_net_paid_inc_tax) AS total_revenue
    FROM 
        sales_data
    GROUP BY 
        d_year, d_quarter_seq, d_month_seq
)
SELECT 
    d_year AS year,
    d_quarter_seq AS quarter,
    d_month_seq AS month,
    item_count,
    total_profit,
    avg_profit_per_item,
    total_revenue,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM 
    profit_analysis
ORDER BY 
    year, quarter, month;
