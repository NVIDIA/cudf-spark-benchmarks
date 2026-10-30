
WITH  sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_id, s.s_store_name
    HAVING 
        COUNT(ss.ss_ticket_number) > 0
), 

customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),

top_stores AS (
    SELECT 
        * 
    FROM 
        sales_hierarchy 
    WHERE 
        sales_rank <= 5
),

top_customers AS (
    SELECT 
        *
    FROM 
        customer_analysis 
    WHERE 
        customer_rank <= 10
)

SELECT 
    ts.s_store_id,
    ts.s_store_name,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(tc.purchase_count, 0) AS purchase_count,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    top_stores ts
FULL OUTER JOIN 
    top_customers tc ON ts.total_sales = tc.purchase_count
ORDER BY 
    ts.s_store_name, tc.total_spent DESC;
