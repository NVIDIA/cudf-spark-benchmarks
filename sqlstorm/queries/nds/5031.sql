
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
TopReturningItems AS (
    SELECT 
        rr.sr_item_sk, 
        i.i_item_desc, 
        i.i_current_price,
        rr.total_returned,
        rr.total_return_amt
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.return_rank <= 5
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amt
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_item_sk
),
ReturnImpact AS (
    SELECT 
        tsi.sr_item_sk,
        tsi.i_item_desc,
        tsi.i_current_price,
        COALESCE(ss.total_sold, 0) AS total_sold,
        tsi.total_returned,
        tsi.total_return_amt,
        (tsi.total_return_amt / NULLIF(ss.total_sales_amt, 0)) * 100 AS return_percentage
    FROM 
        TopReturningItems tsi
    LEFT JOIN 
        SalesSummary ss ON tsi.sr_item_sk = ss.ws_item_sk
)
SELECT 
    r.sr_item_sk,
    r.i_item_desc,
    r.total_sold,
    r.total_returned,
    r.total_return_amt,
    r.return_percentage
FROM 
    ReturnImpact r
WHERE 
    r.return_percentage > 10
ORDER BY 
    r.return_percentage DESC;
