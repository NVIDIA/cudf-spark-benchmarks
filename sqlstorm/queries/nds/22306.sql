
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
FilteredSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(RR.total_returned, 0) AS total_returned,
    COALESCE(FS.total_quantity, 0) AS total_sold,
    (COALESCE(FS.total_quantity, 0) - COALESCE(RR.total_returned, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(FS.total_quantity, 0) > 0 THEN ROUND((COALESCE(RR.total_returned, 0) / COALESCE(FS.total_quantity, 0)) * 100, 2)
        ELSE NULL 
    END AS return_rate_percentage,
    CONCAT('Item: ', i.i_item_desc, ' | Returns: ', COALESCE(RR.total_returned, 0), ' | Sales: ', COALESCE(FS.total_quantity, 0)) AS sales_summary
FROM 
    item i
LEFT JOIN (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rnk <= 5
    GROUP BY 
        sr_item_sk
) RR ON i.i_item_sk = RR.sr_item_sk
LEFT JOIN FilteredSales FS ON i.i_item_sk = FS.ws_item_sk
WHERE 
    (COALESCE(FS.total_quantity, 0) > 5 OR COALESCE(RR.total_returned, 0) > 0)
    AND (i.i_current_price > (SELECT AVG(ws_net_paid) FROM web_sales WHERE ws_item_sk = i.i_item_sk) 
         OR i.i_current_price IS NULL)
GROUP BY 
    i.i_item_id, i.i_item_desc, i.i_current_price, RR.total_returned, FS.total_quantity
ORDER BY 
    net_sales DESC, 
    return_rate_percentage ASC
LIMIT 50;
