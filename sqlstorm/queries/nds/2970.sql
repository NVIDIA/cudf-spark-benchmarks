
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS online_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0)) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.online_orders,
        cs.store_orders,
        cs.catalog_orders,
        cs.spending_rank,
        d.d_year
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    WHERE cs.total_spent > 1000 AND d.d_year = 2023
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.online_orders,
    h.store_orders,
    h.catalog_orders,
    h.spending_rank,
    CASE 
        WHEN h.online_orders > 0 THEN 'Online Shopper'
        WHEN h.store_orders > 0 THEN 'Store Shopper'
        ELSE 'Catalog Shopper'
    END AS shopper_type
FROM HighSpenders h
ORDER BY h.total_spent DESC;
