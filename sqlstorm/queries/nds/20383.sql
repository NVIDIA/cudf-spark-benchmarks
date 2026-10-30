
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
recent_returns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    WHERE wr_returned_date_sk = (
        SELECT MAX(wr_returned_date_sk) 
        FROM web_returns 
        WHERE wr_returned_date_sk IS NOT NULL
    )
    GROUP BY wr_item_sk
),
sales_and_returns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_return_amt, 0.00) AS total_return_amt,
        rs.total_sales - COALESCE(rr.total_return_amt, 0.00) AS net_sales
    FROM ranked_sales rs
    LEFT JOIN recent_returns rr ON rs.ws_item_sk = rr.wr_item_sk
)
SELECT 
    sa.ws_item_sk,
    sa.total_sales,
    sa.total_returns,
    sa.total_return_amt,
    sa.net_sales,
    CASE 
        WHEN sa.net_sales > 10000 THEN 'High Performer'
        WHEN sa.net_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    STRING_AGG(CASE 
        WHEN sa.total_returns > 0 THEN 'Item has returns' 
        ELSE 'No returns' 
    END, '; ') AS return_status
FROM sales_and_returns sa
GROUP BY sa.ws_item_sk, sa.total_sales, sa.total_returns, sa.total_return_amt, sa.net_sales
HAVING COUNT(sa.ws_item_sk) > 1 OR SUM(sa.total_sales) IS NULL
ORDER BY performance_category, net_sales DESC
LIMIT 10;
