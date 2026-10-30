WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        ws.ws_net_profit,
        COALESCE(ws.ws_sales_price - ws.ws_ext_discount_amt, 0) AS net_price,
        CASE
            WHEN ws.ws_sales_price > 100 THEN 'High'
            WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2001)
),
FilteredReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS unique_returns
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d.d_date_sk 
                                       FROM date_dim d 
                                       WHERE d.d_year = 2001 AND d.d_dow IN (6, 0)) 
    GROUP BY wr.wr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.ws_sales_price,
    f.total_returned,
    f.total_return_amt,
    f.unique_returns,
    (s.ws_net_profit - COALESCE(f.total_return_amt, 0)) AS adjusted_net_profit,
    CASE 
        WHEN f.unique_returns IS NULL AND s.ws_sales_price IS NOT NULL THEN 'No Returns'
        WHEN f.total_returned > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS sale_status
FROM RankedSales s
LEFT JOIN FilteredReturns f ON s.ws_item_sk = f.wr_item_sk 
WHERE s.rn = 1 
AND s.net_price > (SELECT AVG(ws_sales_price) 
                   FROM web_sales 
                   WHERE ws_sold_date_sk > (SELECT MIN(d.d_date_sk) 
                                             FROM date_dim d 
                                             WHERE d.d_year = 2000))
ORDER BY adjusted_net_profit DESC
LIMIT 20;