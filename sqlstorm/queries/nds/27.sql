
WITH sales_summary AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS item_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT DISTINCT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2022 AND d.d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(cs.total_quantity) AS total_quantity_sold,
    SUM(cs.total_net_paid) AS total_net_sales,
    AVG(cs.total_net_paid) AS average_net_sales_per_item,
    COUNT(DISTINCT cs.item_rank) AS unique_items_ranked
FROM customer_address ca
JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_summary cs ON cs.cs_item_sk IN (
    SELECT cs_item_sk 
    FROM catalog_sales 
    GROUP BY cs_item_sk 
    HAVING SUM(cs_quantity) > 100
)
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_net_sales DESC
LIMIT 10;
