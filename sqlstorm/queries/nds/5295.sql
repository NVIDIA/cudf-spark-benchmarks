
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq,
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS average_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_quarter_seq, d.d_month_seq, s.s_store_name
),
top_stores AS (
    SELECT 
        tss.*,
        RANK() OVER (PARTITION BY tss.d_year, tss.d_quarter_seq ORDER BY tss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary tss
)
SELECT 
    ts.d_year,
    ts.d_quarter_seq,
    ts.s_store_name,
    ts.total_sales,
    ts.average_profit,
    ts.unique_customers
FROM 
    top_stores ts
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.d_year, ts.d_quarter_seq, ts.total_sales DESC;
