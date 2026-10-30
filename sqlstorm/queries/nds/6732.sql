
WITH base_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq
),
benchmark_data AS (
    SELECT 
        base_data.*,
        RANK() OVER (PARTITION BY d_month_seq ORDER BY total_spent DESC) AS rank_by_month,
        NTILE(10) OVER (ORDER BY total_spent DESC) AS decile
    FROM 
        base_data
)
SELECT 
    rank_by_month,
    decile,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent,
    AVG(total_purchases) AS avg_purchases,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers
FROM 
    benchmark_data
GROUP BY 
    rank_by_month, decile
ORDER BY 
    rank_by_month, decile;
