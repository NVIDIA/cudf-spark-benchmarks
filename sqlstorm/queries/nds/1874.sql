
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopProfitItems AS (
    SELECT 
        sd.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.profit_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemPerformance AS (
    SELECT 
        tpi.ws_item_sk,
        tpi.i_item_desc,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        tpi.total_quantity,
        tpi.total_net_profit,
        (tpi.total_net_profit - COALESCE(cr.total_return_amt, 0)) AS net_profit_after_returns
    FROM 
        TopProfitItems tpi
    LEFT JOIN 
        CustomerReturns cr ON tpi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    ip.ws_item_sk,
    ip.i_item_desc,
    ip.total_quantity,
    ip.total_net_profit,
    ip.total_returns,
    ip.total_return_amt,
    CASE 
        WHEN ip.net_profit_after_returns < 0 THEN 'Negative Profit'
        WHEN ip.net_profit_after_returns BETWEEN 0 AND 100 THEN 'Low Profit'
        WHEN ip.net_profit_after_returns BETWEEN 101 AND 500 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    ItemPerformance ip
ORDER BY 
    ip.net_profit_after_returns DESC;
