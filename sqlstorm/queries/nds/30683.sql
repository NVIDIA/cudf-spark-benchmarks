WITH  Sales_Rank AS (
    SELECT ws_item_sk, 
           ws_order_number,
           ws_quantity,
           ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
),
Aggregate_Data AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        a.c_customer_sk,
        a.total_profit,
        a.total_orders,
        a.max_purchase_estimate,
        a.avg_purchase_estimate,
        RANK() OVER (ORDER BY a.total_profit DESC) as customer_rank
    FROM Aggregate_Data a
)
SELECT 
    tc.c_customer_sk,
    tc.total_profit,
    tc.total_orders,
    tc.max_purchase_estimate,
    tc.avg_purchase_estimate,
    sr.rank AS item_rank,
    i.i_item_id,
    i.i_item_desc
FROM Top_Customers tc
LEFT JOIN Sales_Rank sr ON tc.c_customer_sk = sr.ws_order_number 
LEFT JOIN item i ON sr.ws_item_sk = i.i_item_sk
WHERE tc.total_profit > (SELECT AVG(total_profit) FROM Aggregate_Data) 
AND tc.total_orders > 5 
ORDER BY tc.total_profit DESC, item_rank
LIMIT 10;