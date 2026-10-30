
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_desc,
        SUM(rr.sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT rr.sr_customer_sk) AS unique_customers
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.rnk <= 10
    GROUP BY 
        rr.sr_item_sk, i.i_item_desc
),
SalesStats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tr.i_item_desc,
    tr.total_returned_quantity,
    ss.total_sold_quantity,
    ss.total_profit,
    (CAST(tr.total_returned_quantity AS decimal) / NULLIF(ss.total_sold_quantity, 0)) * 100 AS return_rate
FROM 
    TopReturns tr
JOIN 
    SalesStats ss ON tr.sr_item_sk = ss.ws_item_sk
ORDER BY 
    return_rate DESC
LIMIT 10;
