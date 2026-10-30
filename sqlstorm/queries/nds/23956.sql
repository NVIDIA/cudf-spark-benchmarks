
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(c.return_count, 0) AS return_count,
        COALESCE(c.total_return_amount, 0) AS total_return_amount
    FROM item i
    LEFT JOIN CustomerReturns c ON i.i_item_sk = c.sr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    SUM(id.total_return_amount) AS total_returned,
    AVG(id.i_current_price) AS avg_price,
    COUNT(rs.ws_order_number) AS total_sales,
    CASE 
        WHEN SUM(id.total_return_amount) > AVG(id.i_current_price) * COUNT(rs.ws_order_number) THEN 'High Returns'
        ELSE 'Normal'
    END AS return_status,
    SUBSTRING(id.i_item_desc, 1, CASE WHEN LENGTH(id.i_item_desc) > 20 THEN 20 ELSE LENGTH(id.i_item_desc) END) AS short_desc,
    NULLIF(MAX(id.return_count), 0) AS max_returns
FROM ItemDetails id
JOIN RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.rank = 1
GROUP BY id.i_item_sk, id.i_item_desc
HAVING SUM(NULLIF(id.total_return_amount, 0)) > 0
ORDER BY total_returned DESC, avg_price ASC
LIMIT 50;
