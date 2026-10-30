
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
ReturnsSummary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
FinalReport AS (
    SELECT 
        ss.ws_item_sk,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) = 0 THEN NULL 
            ELSE ((COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amt, 0)) / COALESCE(ss.total_sales, 0)) * 100 
        END AS sales_return_rate
    FROM SalesSummary ss
    FULL OUTER JOIN ReturnsSummary rs ON ss.ws_item_sk = rs.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_return_amt,
    f.sales_return_rate
FROM FinalReport f
JOIN item i ON f.ws_item_sk = i.i_item_sk
WHERE f.sales_return_rate IS NULL OR f.sales_return_rate > 20.0
ORDER BY f.sales_return_rate DESC NULLS LAST;
