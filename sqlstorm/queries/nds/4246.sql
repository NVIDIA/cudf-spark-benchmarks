
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.web_orders,
        cs.catalog_orders,
        cs.store_orders,
        (cs.total_quantity / NULLIF((cs.web_orders + cs.catalog_orders + cs.store_orders), 0)) AS avg_quantity_per_order
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    sm.c_customer_sk,
    sm.c_first_name,
    sm.c_last_name,
    sm.total_quantity,
    sm.web_orders,
    sm.catalog_orders,
    sm.store_orders,
    sm.avg_quantity_per_order,
    CASE 
        WHEN sm.avg_quantity_per_order > 10 THEN 'High Value'
        WHEN sm.avg_quantity_per_order BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM SalesMetrics sm
WHERE sm.total_quantity > (
    SELECT AVG(total_quantity)
    FROM CustomerSales
) 
ORDER BY sm.total_quantity DESC
LIMIT 100;
