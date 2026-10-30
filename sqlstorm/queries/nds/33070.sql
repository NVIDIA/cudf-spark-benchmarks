
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_net_profit > 0

    UNION ALL

    SELECT 
        c.cs_order_number,
        c.cs_item_sk,
        c.cs_quantity,
        c.cs_net_profit + s.ws_net_profit,
        s.level + 1
    FROM catalog_sales c
    JOIN SalesCTE s ON c.cs_order_number = s.ws_order_number AND c.cs_item_sk = s.ws_item_sk
    WHERE s.level < 5
)
SELECT 
    ca_state,
    SUM(ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_net_profit) AS avg_profit_per_order,
    MAX(ws_net_profit) AS max_profit,
    MIN(ws_net_profit) AS min_profit,
    STRING_AGG(DISTINCT CAST(ws_item_sk AS STRING), ', ') AS items_sold,
    CASE 
        WHEN AVG(ws_net_profit) IS NULL THEN 'No Profit Data'
        ELSE 'Profit Data Available'
    END AS profit_data_status
FROM web_sales ws
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
GROUP BY ca_state
HAVING COUNT(DISTINCT ws_order_number) > 10
ORDER BY total_quantity_sold DESC;
