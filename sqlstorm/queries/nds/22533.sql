
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6)
    GROUP BY ws_item_sk
), 
AddressInfo AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state,
        CASE 
            WHEN ca_city IS NULL OR ca_state IS NULL THEN 'Unknown'
            ELSE CONCAT(ca_city, ', ', ca_state)
        END AS full_address
    FROM customer_address
), 
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        ai.full_address
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    JOIN AddressInfo ai ON ai.ca_address_sk = i.i_manager_id
    WHERE rs.rank = 1 AND rs.total_net_profit > 1000
), 
FinalResults AS (
    SELECT 
        hpi.ws_item_sk, 
        hpi.total_quantity,
        hpi.total_net_profit,
        COALESCE(ROUND(hpi.total_net_profit / NULLIF(hpi.total_quantity, 0), 2), 0) AS avg_profit_per_item,
        CASE 
            WHEN hpi.full_address LIKE '%Unknown%' THEN 'Location Undefined'
            ELSE hpi.full_address
        END AS address_display
    FROM HighProfitItems hpi
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_net_profit,
    fr.avg_profit_per_item,
    fr.address_display 
FROM FinalResults fr
WHERE 
    fr.avg_profit_per_item > (SELECT AVG(avg_profit_per_item) FROM FinalResults)
ORDER BY fr.total_net_profit DESC
LIMIT 10;
