
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_order
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
LeftJoinedSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price,
        COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(tr.total_return_amount, 0) AS total_return_amount,
        rs.rank_order
    FROM 
        RankedSales AS rs
    LEFT JOIN 
        TotalReturns AS tr ON rs.ws_item_sk = tr.sr_item_sk
)
SELECT 
    lj.ws_order_number,
    lj.ws_item_sk,
    lj.ws_quantity,
    lj.ws_sales_price,
    lj.total_return_quantity,
    lj.total_return_amount,
    (lj.ws_sales_price * lj.ws_quantity - lj.total_return_amount) AS net_sales,
    CASE 
        WHEN lj.total_return_quantity > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    LeftJoinedSales AS lj
WHERE 
    lj.rank_order = 1
    AND lj.ws_sales_price IS NOT NULL
ORDER BY 
    net_sales DESC 
LIMIT 50;
