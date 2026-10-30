WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as sales_rank
    FROM 
        web_sales
),
FilteredReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS total_orders
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
OuterJoinSalesAndReturns AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(r.total_returned, 0) AS total_returned,
        s.ws_quantity,
        s.ws_sales_price
    FROM 
        RankedSales AS s
    LEFT JOIN 
        FilteredReturns AS r 
    ON 
        s.ws_item_sk = r.wr_item_sk
    WHERE 
        s.sales_rank = 1
)
SELECT 
    i.i_item_id,
    s.ws_quantity,
    s.ws_sales_price,
    s.total_returned,
    CASE 
        WHEN s.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN s.total_returned / NULLIF(s.ws_quantity, 0) > 0.5 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_status
FROM 
    OuterJoinSalesAndReturns AS s
JOIN 
    item AS i 
ON 
    s.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_rec_start_date <= cast('2002-10-01' as date))
    AND (i.i_category_id IN (SELECT DISTINCT i_category_id FROM item) OR s.total_returned IS NULL)
ORDER BY 
    return_status ASC, return_rate_status DESC
LIMIT 100;