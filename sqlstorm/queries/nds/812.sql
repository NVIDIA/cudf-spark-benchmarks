
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
store_sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_store_orders,
        MAX(ss.ss_net_profit) AS max_net_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY s.s_store_id
),
ranked_customer_sales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_orders,
        cs.avg_net_paid,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM customer_sales cs
),
combined_sales AS (
    SELECT 
        r.c_customer_id AS customer_id,
        r.total_web_sales,
        r.total_orders,
        r.avg_net_paid,
        ss.total_store_sales,
        ss.total_store_orders,
        ss.max_net_profit
    FROM ranked_customer_sales r
    FULL OUTER JOIN store_sales_summary ss ON r.total_orders > ss.total_store_orders
)
SELECT 
    COALESCE(customer_id, 'No Customer') AS customer_id,
    COALESCE(total_web_sales, 0) AS total_web_sales,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(avg_net_paid, 0) AS avg_net_paid,
    COALESCE(total_store_sales, 0) AS total_store_sales,
    COALESCE(total_store_orders, 0) AS total_store_orders,
    COALESCE(max_net_profit, 0) AS max_net_profit,
    CASE 
        WHEN COALESCE(total_web_sales, 0) > COALESCE(total_store_sales, 0) THEN 'Web Sales Dominant'
        WHEN COALESCE(total_store_sales, 0) > COALESCE(total_web_sales, 0) THEN 'Store Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance
FROM combined_sales
WHERE (total_web_sales IS NOT NULL OR total_store_sales IS NOT NULL)
ORDER BY customer_id;
