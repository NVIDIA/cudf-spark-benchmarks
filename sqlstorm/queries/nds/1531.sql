
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_info AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS count_customers,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
top_spenders AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.count_customers,
    ds.avg_spent,
    COALESCE(ts.total_spent, 0) AS top_spender_amount,
    COALESCE(ts.rank, NULL) AS rank_of_top_spender
FROM 
    demographic_info ds
LEFT JOIN top_spenders ts ON ds.count_customers = (
    SELECT 
        MAX(count_customers) 
    FROM 
        demographic_info
) 
WHERE 
    ds.avg_spent IS NOT NULL
ORDER BY 
    ds.cd_gender, ds.cd_marital_status;
