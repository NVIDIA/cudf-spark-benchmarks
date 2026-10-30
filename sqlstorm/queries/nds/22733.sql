
WITH RecursiveSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
FinalMetrics AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(rs.cumulative_sales, 0) AS total_sales,
        COALESCE(ir.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(ir.total_returns, 0) = 0 THEN NULL
            ELSE (COALESCE(rs.cumulative_sales, 0) / COALESCE(ir.total_returns, 1)) 
        END AS sales_to_returns_ratio
    FROM
        item i
    LEFT JOIN RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN ItemReturns ir ON i.i_item_sk = ir.wr_item_sk
)
SELECT 
    fm.i_item_id,
    fm.total_sales,
    fm.total_returns,
    CASE 
        WHEN fm.sales_to_returns_ratio IS NULL THEN 'No Returns'
        WHEN fm.sales_to_returns_ratio < 1 THEN 'High Return Rate'
        ELSE 'Optimized Sales'
    END AS return_analysis
FROM 
    FinalMetrics fm
WHERE 
    fm.total_sales > 1000
    AND (fm.total_returns IS NULL OR fm.total_returns < 10)
ORDER BY 
    fm.total_sales DESC, 
    fm.total_returns ASC
LIMIT 50;
