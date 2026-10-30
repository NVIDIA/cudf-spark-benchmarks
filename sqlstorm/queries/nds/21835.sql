
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0 AND i.i_size IS NOT NULL
),
customer_address_info AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
high_performance_addresses AS (
    SELECT 
        ca.ca_city, 
        ca.ca_state,
        MAX(ca.customer_count) AS max_customers
    FROM customer_address_info ca
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.rank_price,
    r.rank_quantity,
    a.ca_city,
    a.ca_state
FROM ranked_sales r
LEFT JOIN customer_address_info a ON r.ws_item_sk = a.ca_address_sk 
WHERE r.rank_price = 1 AND 
      (a.ca_state IS NULL OR a.ca_state IN 
       (SELECT ca_state FROM high_performance_addresses WHERE max_customers > 0))
ORDER BY r.ws_order_number DESC, 
         r.ws_item_sk, 
         r.rank_price;
