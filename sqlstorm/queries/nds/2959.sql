
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity_sold,
        r.total_sales_value,
        COALESCE(s.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(s.total_returned_value, 0) AS total_returned_value,
        (r.total_sales_value - COALESCE(s.total_returned_value, 0)) AS net_sales_value
    FROM 
        RankedSales r
    LEFT JOIN 
        SalesReturns s ON r.ws_item_sk = s.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.total_quantity_sold,
    s.total_sales_value,
    s.total_returned_quantity,
    s.total_returned_value,
    s.net_sales_value,
    CASE 
        WHEN s.net_sales_value IS NULL THEN 'No Sales'
        WHEN s.net_sales_value > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS sales_status
FROM 
    SalesWithReturns s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    s.total_quantity_sold > 10
    AND i.i_current_price IS NOT NULL
ORDER BY 
    s.total_sales_value DESC
LIMIT 50;
