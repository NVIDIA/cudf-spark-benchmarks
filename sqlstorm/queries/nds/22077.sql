WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), ReturnInfo AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), FinalSales AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        (COALESCE(rs.total_sales, 0) - COALESCE(ri.total_return_amount, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN NULL 
            ELSE (COALESCE(ri.total_return_amount, 0) / COALESCE(rs.total_sales, 0)) * 100 
        END AS return_percentage
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
    LEFT JOIN 
        ReturnInfo ri ON i.i_item_sk = ri.wr_item_sk
    WHERE 
        (COALESCE(rs.total_sales, 0) > 0 OR COALESCE(ri.total_returns, 0) > 0)
)

SELECT 
    f.i_item_id,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    f.return_percentage,
    CASE 
        WHEN f.return_percentage IS NULL THEN 'No sales' 
        WHEN f.return_percentage < 10 THEN 'Healthy' 
        WHEN f.return_percentage BETWEEN 10 AND 20 THEN 'Moderate Impact' 
        ELSE 'High Returns' 
    END AS return_status
FROM 
    FinalSales f
ORDER BY 
    f.net_sales DESC;