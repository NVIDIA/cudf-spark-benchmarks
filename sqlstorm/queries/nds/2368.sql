
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE
            WHEN COALESCE(cr.total_return_amt, 0) > 0 THEN 'Returned'
            ELSE 'Sold'
        END AS sale_status
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_item_sk = cr.sr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    COUNT(swr.ws_item_sk) AS sale_count,
    SUM(swr.ws_quantity) AS total_quantity_sold,
    AVG(swr.ws_sales_price) AS avg_sales_price,
    SUM(swr.total_returns) AS total_returns,
    AVG(swr.total_return_amt) AS avg_return_amount,
    SUM(CASE WHEN swr.sale_status = 'Returned' THEN 1 ELSE 0 END) AS total_returned_sales
FROM 
    SalesWithReturns swr
JOIN 
    item ON swr.ws_item_sk = item.i_item_sk
WHERE 
    swr.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
GROUP BY 
    item.i_item_id, item.i_item_desc
HAVING 
    SUM(swr.ws_quantity) > 100
ORDER BY 
    total_quantity_sold DESC;
