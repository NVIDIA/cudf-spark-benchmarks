
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returned,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY rr.total_returned DESC) AS item_rank
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.rank <= 5
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq, ws.ws_item_sk
),
SalesVsReturns AS (
    SELECT 
        t.item_rank,
        t.i_item_desc,
        COALESCE(s.total_sold, 0) AS total_sold,
        COALESCE(r.total_returned, 0) AS total_returned,
        (COALESCE(r.total_returned, 0) * 100.0 / NULLIF(s.total_sold, 0)) AS return_percentage
    FROM 
        TopReturnedItems t
    LEFT JOIN 
        MonthlySales s ON t.sr_item_sk = s.ws_item_sk
    LEFT JOIN 
        RankedReturns r ON t.sr_item_sk = r.sr_item_sk
    WHERE 
        s.d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim)
)
SELECT 
    item_rank,
    i_item_desc,
    total_sold,
    total_returned,
    return_percentage
FROM 
    SalesVsReturns
WHERE 
    return_percentage > 50 OR (return_percentage IS NULL AND total_sold = 0)
ORDER BY 
    return_percentage DESC, total_sold DESC;
