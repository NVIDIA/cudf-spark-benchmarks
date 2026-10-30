
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(AR.total_returns, 0) AS total_returns,
    COALESCE(AR.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(AR.total_return_amount, 0) = 0 THEN 'No Returns'
        WHEN COALESCE(RS.total_sales, 0) = 0 THEN 'No Sales'
        ELSE ROUND((COALESCE(AR.total_return_amount, 0) / COALESCE(RS.total_sales, 1)) * 100, 2) || '%' 
    END AS return_percentage
FROM 
    item i
LEFT JOIN 
    RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.rn = 1
LEFT JOIN 
    AggregatedReturns AR ON i.i_item_sk = AR.wr_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
ORDER BY 
    total_sales DESC
LIMIT 10;
