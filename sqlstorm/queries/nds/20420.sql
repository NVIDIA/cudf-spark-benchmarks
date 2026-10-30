
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        t.d_date AS sales_date
    FROM 
        RankedSales r
    JOIN 
        date_dim t ON r.sales_rank = 1
    WHERE 
        r.total_sales IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0 
        AND EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_item_sk = sr_item_sk AND ws.ws_net_profit < 0)
    GROUP BY 
        sr_item_sk
)
SELECT 
    tsi.ws_item_sk AS item_id,
    tsi.total_quantity AS total_quantity_sold,
    tsi.total_sales AS total_sales_value,
    COALESCE(cr.return_count, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_returned_value,
    CASE 
        WHEN tsi.total_sales > COALESCE(cr.total_return_value, 0) 
        THEN 'Profitable' 
        ELSE 'Not Profitable' 
    END AS profitability_status
FROM 
    TopSellingItems tsi
LEFT JOIN 
    CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
WHERE 
    tsi.total_sales > 1000
ORDER BY 
    total_sales_value DESC
LIMIT 10;
