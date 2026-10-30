
WITH customer_with_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN total_spent < 100 THEN 'Low'
            WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS spending_category,
        COUNT(c_customer_sk) AS customer_count,
        AVG(total_spent) AS avg_spent
    FROM customer_with_sales
    GROUP BY spending_category
)
SELECT 
    spending_category,
    customer_count,
    avg_spent,
    ROW_NUMBER() OVER (ORDER BY avg_spent DESC) AS rank
FROM sales_summary
ORDER BY spending_category;
