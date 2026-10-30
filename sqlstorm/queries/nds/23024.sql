
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rn = 1
    GROUP BY 
        sr_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022 AND d_month_seq = 12) 
        AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1)
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(tr.total_returned, 0) AS total_returns,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL 
        ELSE ROUND((COALESCE(tr.total_returned, 0) * 1.0 / sd.total_sales) * 100, 2) 
    END AS return_rate
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    TopReturns tr ON i.i_item_sk = tr.sr_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    AND (i.i_item_desc LIKE '%special%' OR i.i_item_desc IS NULL)
ORDER BY 
    return_rate DESC NULLS LAST
LIMIT 10;
