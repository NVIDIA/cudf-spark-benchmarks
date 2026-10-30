
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        sa.ca_city,
        sa.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458849 AND 2459237  
),
AggregateSales AS (
    SELECT
        ws_item_sk AS item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM SalesData
    WHERE rn = 1
    GROUP BY ws_item_sk
)
SELECT 
    a.item_sk,
    a.total_net_profit,
    a.order_count,
    a.avg_sales_price,
    CASE 
        WHEN a.total_net_profit IS NULL THEN 'No profit'
        WHEN a.total_net_profit > 1000 THEN 'High Performer'
        WHEN a.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM AggregateSales a
LEFT JOIN inventory inv ON a.item_sk = inv.inv_item_sk AND inv.inv_quantity_on_hand > 0
WHERE inv.inv_quantity_on_hand IS NOT NULL
ORDER BY a.total_net_profit DESC
LIMIT 50;
