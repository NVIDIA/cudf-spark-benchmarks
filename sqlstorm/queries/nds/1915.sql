
WITH TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_sold_date
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnStatistics AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sales,
        ts.order_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0.00) AS total_return_amount,
        ts.last_sold_date,
        (CASE 
            WHEN ts.total_sales > 0 THEN ROUND(COALESCE(rs.total_return_amount, 0) / ts.total_sales * 100, 2)
            ELSE NULL
        END) AS return_rate_percentage
    FROM 
        TotalSales ts
    LEFT JOIN 
        ReturnStatistics rs ON ts.ws_item_sk = rs.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sar.total_sales,
    sar.order_count,
    sar.total_returns,
    sar.total_return_amount,
    sar.return_rate_percentage
FROM 
    SalesAndReturns sar
JOIN 
    item i ON sar.ws_item_sk = i.i_item_sk
WHERE 
    (sar.return_rate_percentage IS NOT NULL AND sar.return_rate_percentage > 10) 
    OR (sar.total_sales > 10000)
ORDER BY 
    sar.return_rate_percentage DESC, 
    sar.total_sales DESC
LIMIT 50;
