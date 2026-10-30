
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchases,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_purchases,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchases
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        web_purchases,
        catalog_purchases,
        store_purchases,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_sales
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.web_purchases,
    tc.catalog_purchases,
    tc.store_purchases
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
