
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns 
    GROUP BY sr_item_sk
),
FilteredReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(tr.total_returned, 0) AS total_returned,
        CASE 
            WHEN tr.total_returned > 0 THEN 'Returned'
            ELSE 'Not Returned' 
        END AS return_status
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.ws_item_sk = tr.sr_item_sk
    WHERE 
        rs.price_rank = 1 AND rs.quantity_rank < 5
)
SELECT 
    f.ws_item_sk,
    f.ws_order_number,
    f.ws_sales_price,
    f.total_returned,
    f.return_status,
    CASE
        WHEN f.return_status = 'Returned' AND f.total_returned < 10 THEN 'Low Return'
        WHEN f.return_status = 'Returned' AND f.total_returned >= 10 THEN 'High Return'
        ELSE 'No Return'
    END AS return_classification,
    (SELECT 
        COUNT(DISTINCT wr_order_number) 
     FROM 
        web_returns wr 
     WHERE 
        wr.wr_item_sk = f.ws_item_sk 
    ) AS total_web_returns
FROM 
    FilteredReturns f
WHERE 
    f.total_returned IS NOT NULL
ORDER BY 
    f.ws_sales_price DESC, 
    f.ws_order_number ASC
LIMIT 100;
