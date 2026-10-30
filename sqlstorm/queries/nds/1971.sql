
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM customer_sales cs
    WHERE cs.rank <= 10
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
store_performance AS (
    SELECT 
        si.s_store_sk,
        si.s_store_name,
        si.total_sales,
        COALESCE(NULLIF((SELECT AVG(total_sales) FROM store_info), 0), 1) AS avg_store_sales
    FROM store_info si
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    sp.s_store_name,
    sp.total_sales,
    CASE 
        WHEN sp.total_sales > sp.avg_store_sales THEN 'Above Average'
        WHEN sp.total_sales = sp.avg_store_sales THEN 'Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM top_customers tc
JOIN store_performance sp ON (sp.total_sales IS NOT NULL AND sp.total_sales > 0)
ORDER BY tc.total_spent DESC;
