
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_profit_per_order
    FROM 
        customer_sales cs
    WHERE 
        cs.rank <= 10
),
store_sales_info AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS store_revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS transactions,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    s.s_store_id,
    s.s_store_name,
    COALESCE(ssi.store_revenue, 0) AS store_revenue,
    COALESCE(ssi.transactions, 0) AS total_transactions,
    COALESCE(ssi.avg_profit, 0) AS avg_store_profit,
    ts.total_spent,
    CASE 
        WHEN ts.total_spent > 1000 THEN 'High Value'
        WHEN ts.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    top_customers ts
FULL OUTER JOIN 
    store s ON ts.c_customer_sk = s.s_store_sk
LEFT JOIN 
    store_sales_info ssi ON ssi.ss_store_sk = s.s_store_sk
ORDER BY 
    ts.total_spent DESC, store_revenue DESC;
