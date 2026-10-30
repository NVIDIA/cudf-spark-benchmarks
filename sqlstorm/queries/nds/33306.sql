
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        c.ws_item_sk AS item_sk,
        c.total_quantity,
        c.total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        (c.total_sales - COALESCE(r.total_return_amt, 0)) AS net_sales
    FROM 
        (SELECT * FROM SalesCTE WHERE rn = 1) c
    LEFT JOIN 
        CustomerReturns r ON c.ws_item_sk = r.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    swr.total_quantity,
    swr.total_sales,
    swr.total_returned,
    swr.total_return_amt,
    swr.net_sales,
    CASE 
        WHEN swr.net_sales > 1000 THEN 'High Sales'
        WHEN swr.net_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    SalesWithReturns swr
JOIN 
    item i ON swr.item_sk = i.i_item_sk
ORDER BY 
    swr.net_sales DESC
LIMIT 10;
