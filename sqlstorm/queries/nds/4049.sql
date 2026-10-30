
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
),
HighValueItems AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_desc,
        ir.i_current_price * 1.1 AS adjusted_price
    FROM 
        item ir
    WHERE 
        ir.i_current_price IS NOT NULL 
        AND ir.i_current_price > (SELECT AVG(i_current_price) FROM item)
),
SalesAndReturns AS (
    SELECT 
        hs.ws_order_number,
        item.i_item_desc,
        hs.ws_quantity,
        hs.ws_sales_price,
        COALESCE(returns.total_returned, 0) AS total_returned,
        COALESCE(returns.return_count, 0) AS return_count
    FROM 
        RankedSales hs
    JOIN 
        HighValueItems item ON hs.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        AggregatedReturns returns ON hs.ws_item_sk = returns.wr_item_sk
    WHERE 
        hs.rnk = 1
)
SELECT 
    sa.ws_order_number AS order_number,
    sa.i_item_desc,
    sa.ws_quantity,
    sa.ws_sales_price,
    sa.total_returned,
    sa.return_count,
    CASE 
        WHEN sa.return_count > 10 THEN 'High Return'
        WHEN sa.return_count BETWEEN 5 AND 10 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_rate_category
FROM 
    SalesAndReturns sa
WHERE 
    sa.ws_quantity > 5
ORDER BY 
    sa.ws_sales_price DESC;
