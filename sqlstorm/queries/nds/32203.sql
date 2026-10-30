WITH  sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
),
top_stores AS (
    SELECT 
        store_rank,
        s_store_sk,
        total_net_profit,
        total_sales
    FROM sales_summary
    WHERE store_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
aggregated_customers AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_spent) AS avg_spent_per_customer
    FROM customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
date_analysis AS (
    SELECT 
        d.d_date,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_net_profit) AS total_profit
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date >= cast('2002-10-01' as date) - INTERVAL '1 year'
    GROUP BY d.d_date
)
SELECT 
    ts.s_store_sk,
    ts.total_net_profit,
    ts.total_sales,
    ac.cd_gender,
    ac.customer_count,
    ac.avg_spent_per_customer,
    da.d_date,
    da.orders_count,
    da.total_profit
FROM top_stores ts
JOIN aggregated_customers ac ON ac.avg_spent_per_customer IS NOT NULL
JOIN date_analysis da ON da.orders_count IS NOT NULL
ORDER BY total_net_profit DESC, total_sales DESC;