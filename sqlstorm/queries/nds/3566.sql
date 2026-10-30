
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS refund_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ItemPerformance AS (
    SELECT 
        ti.ws_item_sk,
        ti.ws_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.refund_amount, 0) AS refund_amount,
        (ti.total_quantity - COALESCE(cr.total_returns, 0)) AS net_sales
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON ti.ws_item_sk = cr.wr_item_sk
)
SELECT 
    ip.ws_item_sk,
    ip.ws_sales_price,
    ip.total_returns,
    ip.refund_amount,
    ip.net_sales,
    CASE 
        WHEN ip.net_sales < 0 THEN 'Negative Sales'
        WHEN ip.net_sales BETWEEN 0 AND 100 THEN 'Low Sales'
        WHEN ip.net_sales BETWEEN 101 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    ItemPerformance ip
WHERE 
    ip.ws_sales_price IS NOT NULL
ORDER BY 
    ip.net_sales DESC
LIMIT 50;
