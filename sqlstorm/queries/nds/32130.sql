
WITH  sales_hierarchy AS (
    SELECT ws_item_sk, ws_order_number, ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sales_price > (
        SELECT AVG(ws_sales_price)
        FROM web_sales
        WHERE ws_sold_date_sk >= (
            SELECT MAX(d_date_sk) - 30
            FROM date_dim
        )
    )
),
aggregated_sales AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_stats AS (
    SELECT c_customer_sk, 
           COUNT(DISTINCT ws_order_number) AS order_count, 
           SUM(ws_sales_price) AS total_spent
    FROM web_sales ws
    INNER JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk
)
SELECT 
    ca_state,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    SUM(cs.cs_sales_price) AS total_catalog_revenue,
    AVG(cs.cs_sales_price) AS avg_catalog_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_sales_price) AS total_store_revenue,
    AVG(ss.ss_sales_price) AS avg_store_price,
    MAX(sales_hierarchy.ws_sales_price) AS highest_web_sales_price
FROM catalog_sales cs
FULL OUTER JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number
INNER JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN sales_hierarchy ON sales_hierarchy.ws_item_sk = cs.cs_item_sk
LEFT JOIN customer_stats ON customer_stats.c_customer_sk = ss.ss_customer_sk
WHERE (ca.ca_state IS NOT NULL)
GROUP BY ca_state
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_catalog_revenue DESC
LIMIT 100;
