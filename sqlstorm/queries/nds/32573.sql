
WITH  sales_hierarchy AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ss.ss_net_paid) DESC) as rank
    FROM 
        warehouse w
    LEFT JOIN 
        store s ON w.w_warehouse_sk = s.s_store_sk
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
    HAVING 
        SUM(ss.ss_net_paid) > 10000
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) as customer_rank
    FROM 
        customer_stats c
    JOIN 
        sales_hierarchy cs ON cs.total_sales > 5000
)
SELECT 
    w.w_warehouse_name,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales
FROM 
    sales_hierarchy w
FULL OUTER JOIN 
    top_customers tc ON w.w_warehouse_name = tc.c_customer_id
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    w.w_warehouse_name, tc.total_sales DESC;
