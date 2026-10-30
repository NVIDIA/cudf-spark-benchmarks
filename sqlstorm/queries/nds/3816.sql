WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 year')
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_sales,
    (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_returns, 0)) / NULLIF(COALESCE(ts.total_sales, 0), 0) AS return_percentage
FROM 
    item i
LEFT JOIN 
    TopItems ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    net_sales DESC,
    return_percentage ASC
LIMIT 10;