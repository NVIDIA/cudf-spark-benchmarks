WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS overall_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_quantity > 100
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    ti.overall_rank
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
WHERE 
    ti.overall_rank <= 10
ORDER BY 
    ti.total_sales DESC;