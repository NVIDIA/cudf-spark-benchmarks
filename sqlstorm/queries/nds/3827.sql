
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_net_profit DESC) AS rank
    FROM SalesData sd
),
CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        SUM(wp.wp_char_count) AS total_web_page_visits,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ci.c_first_name,
    ci.c_last_name,
    ti.total_net_profit AS top_item_net_profit,
    cd.total_orders,
    cd.total_web_page_visits
FROM customer ci
JOIN customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN TopItems ti ON ci.c_customer_sk = ti.ws_item_sk
JOIN CustomerOrders cd ON ci.c_customer_sk = cd.c_customer_sk
WHERE 
    (cd.total_orders IS NOT NULL AND cd.total_web_page_visits IS NOT NULL)
    OR (cd.total_orders IS NULL AND cd.total_web_page_visits IS NULL)
ORDER BY ca.ca_city, top_item_net_profit DESC
LIMIT 100;
