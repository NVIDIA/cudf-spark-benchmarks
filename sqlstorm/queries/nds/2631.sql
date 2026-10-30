
WITH Customer_Sales AS (
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
Ranked_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.online_orders,
        cs.catalog_orders,
        cs.store_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spent_rank
    FROM 
        Customer_Sales cs
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_spent,
    r.online_orders,
    r.catalog_orders,
    r.store_orders,
    CASE 
        WHEN r.spent_rank <= 10 THEN 'Top Customer'
        WHEN r.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    Ranked_Customers r
WHERE 
    r.online_orders > 0 OR r.catalog_orders > 0 OR r.store_orders > 0
ORDER BY 
    r.total_spent DESC
LIMIT 100;
