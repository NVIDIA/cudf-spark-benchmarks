
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ReturnSales AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        COALESCE(tr.total_returns, 0) AS total_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.ws_item_sk = tr.wr_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_sales_price,
    rt.total_returns,
    CASE 
        WHEN rt.total_returns > 5 THEN 'High Return'
        WHEN rt.total_returns BETWEEN 1 AND 5 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales_per_item,
    AVG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS avg_price
FROM 
    ReturnSales rt
JOIN 
    web_sales ws ON rt.ws_order_number = ws.ws_order_number AND rt.ws_item_sk = ws.ws_item_sk
WHERE 
    rt.total_returns IS NOT NULL
ORDER BY 
    rt.total_returns DESC, rt.ws_sales_price DESC;
