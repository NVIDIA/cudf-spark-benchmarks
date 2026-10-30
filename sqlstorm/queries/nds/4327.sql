
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
TopSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.rank_profit,
        r.total_quantity,
        r.total_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank_profit <= 10
),
CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_profit,
        COALESCE(SUM(cr.wr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(cr.wr_return_amt), 0) AS total_return_amt,
        COUNT(DISTINCT cr.wr_returned_date_sk) AS return_days_count
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.wr_item_sk
    GROUP BY 
        ts.ws_item_sk, ts.total_quantity, ts.total_profit
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    f.total_quantity,
    f.total_profit,
    f.total_returns,
    f.total_return_amt,
    f.return_days_count
FROM 
    FinalReport f
JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
WHERE 
    f.total_profit > 1000
ORDER BY 
    f.total_profit DESC,
    f.total_returns ASC
LIMIT 50;
