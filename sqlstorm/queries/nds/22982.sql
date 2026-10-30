
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rnk
    FROM store_sales ss
    WHERE EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = ss.ss_customer_sk
        AND (c.c_birth_month IS NULL OR c.c_birth_month < 6)
    )
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(ws.ws_quantity, 0) AS web_quantity,
        COALESCE(ss.ss_quantity, 0) AS store_quantity,
        COALESCE(ws.ws_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) AS total_net_profit
    FROM SalesData ws
    FULL OUTER JOIN StoreSalesData ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE (ws.rnk = 1 OR ss.rnk = 1)
),
FinalOutput AS (
    SELECT 
        cs.item_sk,
        cs.web_quantity,
        cs.store_quantity,
        cs.total_net_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        CASE 
            WHEN rd.total_returns > 0 THEN 'RETURNED'
            ELSE 'NOT RETURNED'
        END AS return_status
    FROM CombinedSales cs
    LEFT JOIN ReturnData rd ON cs.item_sk = rd.sr_item_sk
)
SELECT 
    f.item_sk,
    f.web_quantity,
    f.store_quantity,
    f.total_net_profit,
    f.total_returns,
    f.return_status
FROM FinalOutput f
WHERE (f.web_quantity < 10 OR f.store_quantity < 10) 
AND f.total_net_profit > (
    SELECT AVG(total_net_profit)
    FROM FinalOutput
) 
ORDER BY f.total_net_profit DESC
LIMIT 100;
