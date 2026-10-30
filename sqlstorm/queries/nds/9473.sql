
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        d.d_year,
        d.d_month_seq
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        s.total_sales,
        s.total_transactions,
        s.distinct_items,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
    JOIN 
        customer c ON s.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.distinct_items,
    tc.sales_rank,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10 OR tc.sales_rank <= 50;
