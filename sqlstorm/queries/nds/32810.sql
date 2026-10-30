
WITH  sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ss_store_sk
), top_stores AS (
    SELECT 
        store.s_store_name AS store_name,
        sh.total_net_profit
    FROM 
        sales_hierarchy sh
    JOIN 
        store ON sh.ss_store_sk = store.s_store_sk
    WHERE 
        sh.rank <= 10
), customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_purchases,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'VIP'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Regular'
            ELSE 'Casual'
        END AS customer_type
    FROM 
        customer_stats cs
    WHERE 
        cs.total_purchases > 0
), sales_report AS (
    SELECT 
        ths.store_name,
        hv.customer_type,
        COUNT(hv.c_customer_id) AS num_customers,
        SUM(hv.total_spent) AS total_revenue
    FROM 
        top_stores ths
    JOIN 
        high_value_customers hv ON ths.store_name = hv.customer_type
    GROUP BY 
        ths.store_name, hv.customer_type
)
SELECT 
    sr.store_name,
    sr.customer_type,
    COALESCE(sr.num_customers, 0) AS num_customers,
    COALESCE(sr.total_revenue, 0) AS total_revenue
FROM 
    (SELECT DISTINCT store_name, 'VIP' AS customer_type FROM top_stores) AS ts
LEFT JOIN 
    sales_report sr ON ts.store_name = sr.store_name AND ts.customer_type = sr.customer_type
ORDER BY 
    COALESCE(sr.total_revenue, 0) DESC;
