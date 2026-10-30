WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Price Unknown' 
            ELSE 'Price Known' 
        END AS price_status
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2000 AND d.d_moy = 12)
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS unique_returns 
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk >= (SELECT MIN(d.d_date_sk) 
                                       FROM date_dim d 
                                       WHERE d.d_year = 2001)
    GROUP BY cr.cr_item_sk
    HAVING SUM(cr.cr_return_quantity) > 0
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    rs.price_rank,
    rs.price_status,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.unique_returns, 0) AS unique_returns,
    CASE 
        WHEN rs.price_rank IS NOT NULL AND cr.unique_returns IS NULL THEN 'No Returns'
        WHEN rs.price_rank IS NOT NULL AND cr.unique_returns > 10 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_analysis
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
WHERE i.i_current_price > 150.00 
ORDER BY return_analysis, rs.price_rank 
LIMIT 100
OFFSET 10;