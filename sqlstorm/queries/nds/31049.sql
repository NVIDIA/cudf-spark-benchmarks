
WITH  SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_current_year = '1')
        AND i.i_rec_end_date IS NULL
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        s.item_sk,
        s.total_quantity,
        s.total_net_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_value, 0) AS total_return_value
    FROM 
        (SELECT ws_item_sk AS item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_net_profit 
         FROM web_sales 
         GROUP BY ws_item_sk) s
    LEFT JOIN 
        CustomerReturns r ON s.item_sk = r.sr_item_sk
)
SELECT 
    si.i_item_id,
    sr.total_quantity,
    sr.total_net_profit,
    sr.total_returns,
    sr.total_return_value,
    (CASE 
        WHEN sr.total_quantity > 0 THEN (sr.total_net_profit / sr.total_quantity) 
        ELSE 0 
     END) AS average_net_profit_per_item,
    (CASE 
        WHEN sr.total_quantity > 0 THEN (sr.total_return_value * 100 / sr.total_net_profit) 
        ELSE 0 
     END) AS return_percentage
FROM 
    SalesAndReturns sr
JOIN 
    item si ON sr.item_sk = si.i_item_sk
WHERE 
    (sr.total_returns > 0 OR sr.total_quantity > 100)
ORDER BY 
    sr.total_net_profit DESC
LIMIT 100;
