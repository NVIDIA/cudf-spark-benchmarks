
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
),
ReturnsSummary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_order_number,
        ts.ws_sales_price,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.return_count, 0) AS return_count
    FROM 
        TopSales ts
    LEFT JOIN 
        ReturnsSummary rs ON ts.ws_item_sk = rs.wr_item_sk
),
FinalMetrics AS (
    SELECT 
        sar.ws_item_sk,
        sar.ws_order_number,
        sar.ws_sales_price,
        sar.total_returns,
        sar.return_count,
        CASE 
            WHEN sar.total_returns > 0 THEN sar.ws_sales_price / NULLIF(sar.total_returns, 0) 
            ELSE sar.ws_sales_price 
        END AS price_per_return
    FROM 
        SalesAndReturns sar
)
SELECT 
    fm.ws_item_sk,
    fm.ws_order_number,
    fm.ws_sales_price,
    fm.total_returns,
    fm.return_count,
    fm.price_per_return,
    CASE 
        WHEN fm.return_count > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS customer_count,
    (SELECT MIN(d_year) FROM date_dim WHERE d_current_year = 'Y') AS earliest_year
FROM 
    FinalMetrics fm
WHERE 
    (fm.total_returns IS NULL OR fm.total_returns < 5) 
    AND fm.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY 
    fm.ws_sales_price DESC
LIMIT 10;
