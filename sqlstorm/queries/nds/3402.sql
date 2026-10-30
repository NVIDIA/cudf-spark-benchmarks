
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_id,
        i.i_item_desc,
        rr.total_returns,
        rr.total_return_value
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.return_rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tri.i_item_id,
    tri.i_item_desc,
    COALESCE(sd.total_sales, 0) AS total_sales,
    tri.total_returns AS total_returns,
    tri.total_return_value AS total_return_value,
    sd.total_profit
FROM 
    TopReturnedItems tri
LEFT JOIN 
    SalesData sd ON tri.sr_item_sk = sd.ws_item_sk
WHERE 
    tri.total_return_value > 1000
ORDER BY 
    tri.total_returns DESC, tri.total_return_value DESC;
