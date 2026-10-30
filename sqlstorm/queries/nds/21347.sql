
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) as total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FilteredReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price,
        COALESCE(tr.total_returned_quantity, 0) AS total_returned_quantity
    FROM 
        RankedSales r
    LEFT JOIN 
        TotalReturns tr ON r.ws_item_sk = tr.sr_item_sk
    WHERE 
        r.price_rank = 1 AND 
        r.total_quantity > 100 AND 
        r.ws_quantity - COALESCE(tr.total_returned_quantity, 0) > 0
),
FinalResults AS (
    SELECT 
        fr.ws_item_sk,
        fr.ws_quantity,
        fr.ws_sales_price,
        CASE 
            WHEN fr.total_returned_quantity > 0 THEN 'Returns Exist' 
            ELSE 'No Returns' 
        END AS return_status,
        ROUND(fr.ws_sales_price * fr.ws_quantity, 2) AS total_sales_value,
        CASE 
            WHEN fr.ws_quantity > 50 THEN 'High Volume' 
            WHEN fr.ws_quantity BETWEEN 20 AND 50 THEN 'Medium Volume' 
            ELSE 'Low Volume' 
        END AS sales_volume_category 
    FROM 
        FilteredReturns fr
)
SELECT 
    fr.ws_item_sk,
    SUM(fr.total_sales_value) AS total_sales,
    COUNT(DISTINCT fr.return_status) AS distinct_return_statuses,
    MAX(fr.sales_volume_category) AS highest_sales_volume_category
FROM 
    FinalResults fr
GROUP BY 
    fr.ws_item_sk
HAVING 
    MAX(fr.sales_volume_category) != 'Low Volume'
ORDER BY 
    total_sales DESC
LIMIT 100;
