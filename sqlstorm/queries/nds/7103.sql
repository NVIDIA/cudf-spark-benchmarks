
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        AVG(ss.ss_net_profit) AS avg_profit,
        MAX(ss.ss_sales_price) AS max_price,
        MIN(ss.ss_sales_price) AS min_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        ss.total_sales,
        ss.total_orders 
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_orders,
    CASE WHEN tc.total_orders > 5 THEN 'High' ELSE 'Low' END AS order_category
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
