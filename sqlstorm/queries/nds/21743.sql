
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 10
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CombinedSalesReturns AS (
    SELECT 
        tsi.ws_item_sk,
        tsi.total_quantity,
        tsi.total_net_paid,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_returned_amt, 0) AS total_returned_amt,
        (tsi.total_net_paid - COALESCE(rd.total_returned_amt, 0)) AS net_profit_after_returns
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        ReturnData rd ON tsi.ws_item_sk = rd.sr_item_sk
)
SELECT 
    c.i_item_id,
    c.i_item_desc,
    cs.total_quantity,
    cs.total_net_paid,
    cs.total_return_quantity,
    cs.total_returned_amt,
    cs.net_profit_after_returns,
    CASE 
        WHEN cs.net_profit_after_returns > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    item c
JOIN 
    CombinedSalesReturns cs ON c.i_item_sk = cs.ws_item_sk
WHERE 
    cs.net_profit_after_returns < (SELECT AVG(total_net_paid) FROM CombinedSalesReturns) 
ORDER BY 
    cs.net_profit_after_returns ASC
LIMIT 5;
