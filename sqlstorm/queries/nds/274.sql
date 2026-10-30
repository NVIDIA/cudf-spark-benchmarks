
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit
    FROM SalesData sd
    WHERE sd.item_rank <= 5
),
ReturnedData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT 
    ts.ws_sold_date_sk,
    i.i_item_id,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (ts.total_profit - COALESCE(rd.total_returns, 0)) AS net_profit_after_returns
FROM TopSales ts
JOIN item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN ReturnedData rd ON ts.ws_item_sk = rd.wr_item_sk
JOIN date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
ORDER BY net_profit_after_returns DESC;
