
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_store_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk, sr_store_sk
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.sr_store_sk,
        rr.total_return_quantity,
        rr.total_return_amt_inc_tax,
        r.r_reason_desc
    FROM 
        RankedReturns rr
    JOIN reason r ON rr.sr_item_sk = r.r_reason_sk
    WHERE 
        rr.rn <= 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (
            SELECT 
                MAX(d.d_date_sk) 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    COALESCE(sd.ws_item_sk, tr.sr_item_sk) AS ws_item_sk,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
    COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit
FROM 
    SalesData sd
FULL OUTER JOIN TopReturns tr ON sd.ws_item_sk = tr.sr_item_sk
WHERE 
    (tr.total_return_quantity IS NULL OR sd.total_sales_quantity IS NULL OR sd.total_net_profit > 0)
ORDER BY 
    total_net_profit DESC, total_return_quantity DESC;
