
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
    GROUP BY ws.ws_item_sk, ws.ws_order_number
)
SELECT 
    sd.ws_item_sk,
    sd.ws_order_number,
    sd.total_quantity,
    sd.total_net_profit,
    RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_net_profit DESC) AS profit_rank
FROM SalesData sd
WHERE sd.total_quantity > 5
ORDER BY sd.total_net_profit DESC
LIMIT 100;
