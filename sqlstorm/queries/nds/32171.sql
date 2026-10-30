
WITH  SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales - sd.total_discount AS net_sales,
        RANK() OVER (ORDER BY sd.total_sales - sd.total_discount DESC) AS rank
    FROM 
        SalesData sd
    WHERE 
        sd.item_rank = 1
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.net_sales,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    CASE 
        WHEN cr.total_returned IS NOT NULL AND cr.total_returned > 0 
        THEN (ts.net_sales / NULLIF(ts.total_quantity - cr.total_returned, 0)) * 100 
        ELSE NULL 
    END AS return_percentage
FROM 
    TopSales ts
LEFT JOIN 
    CustomerReturns cr ON ts.ws_item_sk = cr.cr_item_sk
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.net_sales DESC;
