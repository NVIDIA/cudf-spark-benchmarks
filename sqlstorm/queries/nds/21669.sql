
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
    )
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
    GROUP BY wr_item_sk
),
FinalSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        rs.order_count,
        CASE 
            WHEN cr.return_count > 0 THEN ROUND((COALESCE(cr.total_returns, 0) / rs.order_count) * 100, 2)
            ELSE 0 
        END AS return_percentage
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
    WHERE rs.sales_rank <= 10
),
Aggregated AS (
    SELECT 
        item.i_item_id,
        COALESCE(fs.total_sales, 0) AS total_sales,
        COALESCE(fs.total_returns, 0) AS total_returns,
        fs.return_percentage,
        CASE 
            WHEN fs.return_percentage IS NULL THEN 'No Returns' 
            WHEN fs.return_percentage < 10 THEN 'Low Return Risk'
            ELSE 'High Return Risk' 
        END AS return_risk_category
    FROM item
    LEFT JOIN FinalSales fs ON item.i_item_sk = fs.ws_item_sk
)
SELECT 
    a.i_item_id,
    a.total_sales,
    a.total_returns,
    a.return_percentage,
    a.return_risk_category,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS overall_rank
FROM Aggregated a
WHERE a.total_sales > (SELECT AVG(total_sales) FROM FinalSales)
ORDER BY a.total_sales DESC
LIMIT 5;
